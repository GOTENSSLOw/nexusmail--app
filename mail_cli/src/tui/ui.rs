use ratatui::{prelude::*, widgets::*};
use crate::tui::state::{App, CurrentScreen};

pub fn render(f: &mut Frame, app: &mut App) {
    // 1. Pantallas "Fuera de Sesión" (Sin pestañas)
    match app.current_screen {
        CurrentScreen::Login => {
            render_login(f, app);
            return;
        }
        CurrentScreen::Register => {
            render_register(f, app);
            return;
        }
        _ => {} // Continuar al layout con pestañas
    }

    // 2. Layout principal (Solo para Inbox, Sent, Compose, Read)
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), 
            Constraint::Min(0),
        ])
        .split(f.size());

    render_tabs(f, app, chunks[0]);

    match app.current_screen {
        CurrentScreen::Inbox => render_inbox(f, app, chunks[1]),
        CurrentScreen::Compose => render_compose(f, app, chunks[1]),
        CurrentScreen::Read => render_read(f, app, chunks[1]),
        CurrentScreen::Sent => render_sent(f, app, chunks[1]),
        _ => {}
    }
}

// --- MEJORAS EN LOGIN ---
fn render_login(f: &mut Frame, app: &mut App) {
    // Centramos el login usando un Layout horizontal dentro del vertical
    let vertical_chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage(20),
            Constraint::Length(18), // Espacio fijo para el formulario
            Constraint::Min(0),
        ])
        .split(f.size());

    let horizontal_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage(25),
            Constraint::Percentage(50),
            Constraint::Percentage(25),
        ])
        .split(vertical_chunks[1]);

    let area = horizontal_chunks[1];
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), // Título
            Constraint::Length(3), // Usuario
            Constraint::Length(3), // Password
            Constraint::Length(3), // Botón Registro
            Constraint::Length(3), // Feedback (Error/Success)
            Constraint::Min(0),
        ])
        .split(area);

    // Título con estilo neón
    let title = Paragraph::new(" NEXUS MAIL ")
        .alignment(Alignment::Center)
        .style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .block(Block::default().borders(Borders::ALL).border_type(BorderType::Double).border_style(Style::default().fg(Color::Cyan)));
    f.render_widget(title, chunks[0]);

    // Colores consistentes para el foco
    let active_style = Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD);
    let idle_style = Style::default().fg(Color::Gray);

    f.render_widget(
        Paragraph::new(app.username_input.as_str())
            .block(Block::default().borders(Borders::ALL).title(" Usuario ").border_style(if app.focused_field == 0 { active_style } else { idle_style })),
        chunks[1]
    );

    let pass_hidden = "*".repeat(app.password_input.len());
    f.render_widget(
        Paragraph::new(pass_hidden)
            .block(Block::default().borders(Borders::ALL).title(" Contraseña ").border_style(if app.focused_field == 1 { active_style } else { idle_style })),
        chunks[2]
    );

    // Botón de registro como un campo de foco más
    let reg_btn_style = if app.focused_field == 2 {
        Style::default().fg(Color::Black).bg(Color::LightMagenta).add_modifier(Modifier::BOLD)
    } else {
        Style::default().fg(Color::LightMagenta)
    };
    
    f.render_widget(
        Paragraph::new(" [ Crear cuenta nueva ] ")
            .alignment(Alignment::Center)
            .block(Block::default().borders(Borders::ALL).border_style(reg_btn_style).style(reg_btn_style)),
        chunks[3]
    );

    if let Some(ref msg) = app.error_message {
        f.render_widget(Paragraph::new(format!(" {}", msg)).fg(Color::Red).alignment(Alignment::Center), chunks[4]);
    } else if let Some(ref msg) = app.success_message {
        f.render_widget(Paragraph::new(format!("󰄬 {}", msg)).fg(Color::Green).alignment(Alignment::Center), chunks[4]);
    }
}

fn render_table_view(f: &mut Frame, app: &mut App, area: Rect, title: &str, is_sent: bool) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(3)])
        .split(area);

    // Encabezados dinámicos
    let header_cells = vec![
        Cell::from(" ID "),
        Cell::from(if is_sent { " Destinatario " } else { " Remitente " }),
        Cell::from(" Asunto "),
        Cell::from(" Snippet "),
    ];
    
    let header = Row::new(header_cells)
        .style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .height(1)
        .bottom_margin(1);

    let email_data = if is_sent { &app.sent_emails } else { &app.emails };
    
    let rows = email_data.iter().map(|e| {
        // En Inbox mostramos quién envía, en Sent a quién mandamos
        let contact = if is_sent { e.recipient.clone() } else { e.sender.clone() };
        
        let (icon, color) = if is_sent { 
            ("󰈺", Color::Blue) 
        } else if e.unread { 
            ("󰇮", Color::Yellow) 
        } else { 
            ("󰇰", Color::DarkGray) 
        };

        Row::new(vec![
            Cell::from(format!("#{}", e.id)),
            Cell::from(contact),
            Cell::from(e.subject.clone()),
            Cell::from(e.snippet.clone()).fg(Color::Gray),
            Cell::from(icon).fg(color)
        ]).height(1)
    });

    let table = Table::new(rows, [
            Constraint::Length(5),
            Constraint::Percentage(25),
            Constraint::Percentage(45),
            Constraint::Percentage(25),
            Constraint::Length(4),
        ])
        .header(header)
        .block(Block::default()
            .borders(Borders::ALL)
            .title(format!(" {} ", title))
            .border_type(BorderType::Rounded)
            .border_style(Style::default().fg(if is_sent { Color::Blue } else { Color::Green })))
        .highlight_style(Style::default().bg(Color::Indexed(236)))
        .highlight_symbol("➜ ");

    f.render_stateful_widget(table, chunks[0], &mut app.table_state);

    // Ayuda visual en la parte inferior
    let help_msg = format!(" [j/k] Navegar | [Enter] Leer | [r] Refrescar | Screen: {}", title);
    f.render_widget(
        Paragraph::new(help_msg)
            .alignment(Alignment::Center)
            .block(Block::default().borders(Borders::TOP).border_style(Style::default().fg(Color::DarkGray))),
        chunks[1]
    );
}

fn render_inbox(f: &mut Frame, app: &mut App, area: Rect) {
    render_table_view(f, app, area, "BANDEJA DE ENTRADA", false);
}

fn render_sent(f: &mut Frame, app: &mut App, area: Rect) {
    render_table_view(f, app, area, "CORREOS ENVIADOS", true);
}

// --- MEJORAS EN REDACTAR ---
fn render_compose(f: &mut Frame, app: &mut App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), // Para
            Constraint::Length(3), // Asunto
            Constraint::Min(0),    // Cuerpo
            Constraint::Length(3), // Ayuda
        ])
        .split(area);

    let active_field_style = Style::default().fg(Color::Yellow);

    f.render_widget(Paragraph::new(app.to_input.as_str()).block(Block::default().borders(Borders::ALL).title(" Para ").border_style(if app.focused_field == 0 { active_field_style } else { Style::default() })), chunks[0]);
    f.render_widget(Paragraph::new(app.subject_input.as_str()).block(Block::default().borders(Borders::ALL).title(" Asunto ").border_style(if app.focused_field == 1 { active_field_style } else { Style::default() })), chunks[1]);
    f.render_widget(Paragraph::new(app.body_input.as_str()).block(Block::default().borders(Borders::ALL).title(" Mensaje ").border_style(if app.focused_field == 2 { active_field_style } else { Style::default() })), chunks[2]);

    f.render_widget(Paragraph::new(" [TAB] Siguiente | [Enter] Enviar | [Esc] Descartar ").alignment(Alignment::Center).fg(Color::DarkGray), chunks[3]);
}

fn render_tabs(f: &mut Frame, app: &mut App, area: Rect) {
    let titles = vec![" [1] Recibidos ", " [2] Enviados ", " [3] Redactar "];
    let index = match app.current_screen {
        CurrentScreen::Inbox | CurrentScreen::Read => 0,
        CurrentScreen::Sent => 1,
        CurrentScreen::Compose => 2,
        _ => 0,
    };

    let tabs = Tabs::new(titles)
        .block(Block::default().borders(Borders::ALL).border_type(BorderType::Rounded))
        .select(index)
        .highlight_style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .divider(Span::raw("|").style(Style::default().fg(Color::DarkGray)));

    f.render_widget(tabs, area);
}

fn render_read(f: &mut Frame, app: &mut App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(3)])
        .split(area);

    let body = app.selected_email_body.as_deref().unwrap_or("Cuerpo vacío");
    let content = Paragraph::new(body)
        .block(Block::default().borders(Borders::ALL).title(" Visualizador de Correo ").border_type(BorderType::Rounded).border_style(Style::default().fg(Color::Cyan)))
        .wrap(Wrap { trim: true });

    f.render_widget(content, chunks[0]);
    f.render_widget(Paragraph::new(" [Esc] Volver a la lista ").alignment(Alignment::Center).fg(Color::DarkGray), chunks[1]);
}

fn render_register(f: &mut Frame, app: &mut App) {
    // Reutilizamos la lógica de centrado del login
    let area = f.size();
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3), // Título
            Constraint::Length(3), // User
            Constraint::Length(3), // Pass
            Constraint::Length(3), // Confirm
            Constraint::Length(3), // Feedback
            Constraint::Min(0),
        ])
        .split(area);

    f.render_widget(Paragraph::new(" REGISTRO DE NUEVA CUENTA ").alignment(Alignment::Center).fg(Color::LightMagenta).block(Block::default().borders(Borders::ALL).border_type(BorderType::Double)), chunks[0]);

    let styles = [
        if app.focused_field == 0 { Style::default().fg(Color::Yellow) } else { Style::default() },
        if app.focused_field == 1 { Style::default().fg(Color::Yellow) } else { Style::default() },
        if app.focused_field == 2 { Style::default().fg(Color::Yellow) } else { Style::default() },
    ];

    f.render_widget(Paragraph::new(app.username_input.as_str()).block(Block::default().borders(Borders::ALL).title(" Usuario ").border_style(styles[0])), chunks[1]);
    f.render_widget(Paragraph::new("*".repeat(app.password_input.len())).block(Block::default().borders(Borders::ALL).title(" Contraseña ").border_style(styles[1])), chunks[2]);
    f.render_widget(Paragraph::new("*".repeat(app.confirm_password_input.len())).block(Block::default().borders(Borders::ALL).title(" Confirmar Contraseña ").border_style(styles[2])), chunks[3]);

    if let Some(ref msg) = app.error_message {
        f.render_widget(Paragraph::new(msg.as_str()).fg(Color::Red).alignment(Alignment::Center), chunks[4]);
    }
}