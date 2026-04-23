pub mod state;
pub mod ui;
pub mod handlers;

use std::io;
use crossterm::{
    event::{self, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::prelude::*;

use crate::{services::{fetch_inbox_data, login}, tui::handlers::handle_register_events};
use crate::tui::handlers::{handle_login_events, handle_inbox_events, handle_compose_events, handle_sent_events, handle_read_events};
use crate::tui::state::{CurrentScreen, App};

pub async fn run_tui() -> Result<(), Box<dyn std::error::Error>> {
    // 1. PREPARAR TERMINAL
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();

    // 2. EJECUTAR EL BUCLE (Pasamos la terminal por referencia)
    let res = main_loop(&mut terminal, &mut app).await;

    // 3. RESTAURAR TERMINAL (Esto es vital, si no tu consola quedará mal)
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;

    res // Retornamos el resultado del loop
}

async fn main_loop(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut App,
) -> Result<(), Box<dyn std::error::Error>> {
    loop {
        // Aquí es donde 'terminal' vive y se usa
        terminal.draw(|f| ui::render(f, app))?;

        // Captura de evento
        if let Event::Key(key) = event::read()? {
            // FILTRO CRÍTICO: Evita duplicación de eventos en Linux/Unix
            if key.kind != event::KeyEventKind::Press {
                continue;
            }

            // --- LA MÁQUINA DE ESTADOS ---
            match app.current_screen {
                CurrentScreen::Login => handle_login_events(app, key).await?,
                CurrentScreen::Inbox => handle_inbox_events(app, key).await?,
                CurrentScreen::Compose => handle_compose_events(app, key).await?,
                CurrentScreen::Sent => handle_sent_events(app, key).await?, 
                CurrentScreen::Register => handle_register_events(app, key).await?,
                CurrentScreen::Read => handle_read_events(app, key).await?,
                _ => if key.code == KeyCode::Char('q') { return Ok(()); }
            }
        }
    }
}