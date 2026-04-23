use crossterm::event::{self, KeyCode};
use crate::tui::state::{App, CurrentScreen};

pub async fn handle_login_events(app: &mut App, key: event::KeyEvent) -> Result<(), Box<dyn std::error::Error>> {
    match key.code {
        KeyCode::Enter => {
            // SI el foco está en el botón de registro, cambiamos de pantalla y salimos
            if app.focused_field == 2 {
                app.current_screen = CurrentScreen::Register;
                app.reset_register();
                return Ok(());
            } 
            
            // Si no, intentamos el LOGIN normal
            app.error_message = None; 
            if let Ok(token) = crate::services::login(&app.username_input, &app.password_input).await {
                app.token = Some(token);
                app.current_screen = CurrentScreen::Inbox;
                refresh_current_view(app).await; // <-- Refresco inicial
                app.table_state.select(Some(0));
            } else {
                app.error_message = Some("Fallo de autenticación".to_string());
            }
        }
        KeyCode::Tab => app.focused_field = (app.focused_field + 1) % 3,
        KeyCode::Char(c) => {
            if app.focused_field == 0 { app.username_input.push(c); }
            else { app.password_input.push(c); }
        }
        KeyCode::Backspace => {
            if app.focused_field == 0 { app.username_input.pop(); }
            else { app.password_input.pop(); }
        }
        KeyCode::Esc => return Err("EXIT".into()),

        _ => {}
    }
    Ok(())
}

pub async fn handle_inbox_events(app: &mut App, key: event::KeyEvent) -> Result<(), Box<dyn std::error::Error>> {
    match key.code {
        // --- NAVEGACIÓN GLOBAL ---
        KeyCode::Char('1') => app.current_screen = CurrentScreen::Inbox,
        KeyCode::Char('2') => {
            app.current_screen = CurrentScreen::Sent;
            if let Some(ref token) = app.token {
                // Cargamos los enviados al cambiar de pestaña
                if let Ok(sent) = crate::services::fetch_sent_data(token).await {
                    app.sent_emails = sent; 
                    app.table_state.select(Some(0));
                }
            }
        }
        
        KeyCode::Char('3') => {
            app.reset_compose();
            app.current_screen = CurrentScreen::Compose;
        }

        // --- NAVEGACIÓN DE TABLA ---
        KeyCode::Char('j') | KeyCode::Down => app.next_email(),
        KeyCode::Char('k') | KeyCode::Up => app.previous_email(),
        
        KeyCode::Char('r') => refresh_current_view(app).await, // REFRESCO UNIVERSAL
        
        // Corregir la lectura: Si estoy en Inbox, leo de app.emails
        KeyCode::Enter => {
            if let Some(i) = app.table_state.selected() {
                if let Some(email) = app.emails.get(i) {
                    app.selected_email_body = Some(email.body.clone());
                    app.current_screen = CurrentScreen::Read;
                }
            }
        }

        KeyCode::Char('q') => return Err("EXIT".into()),
        KeyCode::Esc => app.current_screen = CurrentScreen::Login,
        _ => {}
    }
    Ok(())
}

pub async fn handle_compose_events(app: &mut App, key: event::KeyEvent) -> Result<(), Box<dyn std::error::Error>> {
    match key.code {
        // Bloqueamos la navegación numérica mientras se escribe (opcional)
        // Si quieres que funcione, pon aquí KeyCode::Char('1'), etc.

        KeyCode::Esc => {
            app.current_screen = CurrentScreen::Inbox;
            app.focused_field = 0;
        }
        KeyCode::Tab => app.focused_field = (app.focused_field + 1) % 3,
        KeyCode::Char(c) => {
            match app.focused_field {
                0 => app.to_input.push(c),
                1 => app.subject_input.push(c),
                2 => app.body_input.push(c),
                _ => {}
            }
        }
        KeyCode::Backspace => {
            match app.focused_field {
                0 => { app.to_input.pop(); }
                1 => { app.subject_input.pop(); }
                2 => { app.body_input.pop(); }
                _ => {}
            }
        }
        KeyCode::Enter => {
            if let Some(ref token) = app.token {
                if crate::services::send_email(token, &app.to_input, &app.subject_input, &app.body_input).await.is_ok() {
                    app.reset_compose();
                    app.current_screen = CurrentScreen::Inbox;
                }
            }
        }
        _ => {}
    }
    Ok(())
}

pub async fn handle_sent_events(app: &mut App, key: event::KeyEvent) -> Result<(), Box<dyn std::error::Error>> {
    match key.code {
        KeyCode::Char('1') => app.current_screen = CurrentScreen::Inbox,
        KeyCode::Char('2') => app.current_screen = CurrentScreen::Sent, 
        KeyCode::Char('3') => {
            app.reset_compose();
            app.current_screen = CurrentScreen::Compose;
        }
        KeyCode::Char('r') => refresh_current_view(app).await,
        
        KeyCode::Enter => {
            if let Some(i) = app.table_state.selected() {
                if let Some(email) = app.sent_emails.get(i) {
                    app.selected_email_body = Some(email.body.clone());
                    app.current_screen = CurrentScreen::Read;
                }
            }
        }
        
        KeyCode::Esc => app.current_screen = CurrentScreen::Inbox,
        _ => {}
    }
    Ok(())
}

// En src/tui/handlers.rs
pub async fn handle_register_events(app: &mut App, key: event::KeyEvent) -> Result<(), Box<dyn std::error::Error>> {
    match key.code {
        KeyCode::Esc => {
            app.current_screen = CurrentScreen::Login;
            app.reset_register();
        }
        KeyCode::Tab => {
            app.focused_field = (app.focused_field + 1) % 3;
        }
        KeyCode::Char(c) => {
            match app.focused_field {
                0 => app.username_input.push(c),
                1 => app.password_input.push(c),
                2 => app.confirm_password_input.push(c),
                _ => {}
            }
        }
        KeyCode::Backspace => {
            match app.focused_field {
                0 => { app.username_input.pop(); }
                1 => { app.password_input.pop(); }
                2 => { app.confirm_password_input.pop(); }
                _ => {}
            }
        }
        KeyCode::Enter => {
            if app.password_input != app.confirm_password_input {
                app.error_message = Some("Las contraseñas no coinciden".into());
                return Ok(());
            }

            // Llamada al servicio de registro
            match crate::services::create_user(&app.username_input, &app.password_input).await {
                Ok(_) => {
                    app.success_message = Some("¡Registro exitoso! Inicia sesión.".into());
                    app.current_screen = CurrentScreen::Login;
                    app.password_input.clear(); // Por seguridad
                }
                Err(e) => {
                    app.error_message = Some(e.to_string());
                }
            }
        }
        _ => {}
    }
    Ok(())
}


pub async fn handle_read_events(app: &mut App, key: event::KeyEvent) -> Result<(), Box<dyn std::error::Error>> {
    match key.code {
        KeyCode::Esc => app.current_screen = CurrentScreen::Inbox,
        _ => {}
    }
    Ok(())
}


async fn refresh_current_view(app: &mut App) {
    if let Some(ref token) = app.token {
        match app.current_screen {
            CurrentScreen::Inbox => {
                if let Ok(emails) = crate::services::fetch_inbox_data(token).await {
                    app.emails = emails;
                }
            }
            CurrentScreen::Sent => {
                if let Ok(sent) = crate::services::fetch_sent_data(token).await {
                    app.sent_emails = sent;
                }
            }
            _ => {} // Otras pantallas no necesitan refresco de listas
        }
    }
}