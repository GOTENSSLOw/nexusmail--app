#[derive(PartialEq)]
pub enum CurrentScreen {
    Login,
    Register,
    Inbox,
    Sent,
    Loading,
    Compose,
    Read,
}

pub enum InputMode {
    Normal,
    Editing,
}

pub struct App {
    pub current_screen: CurrentScreen,
    pub input_mode: InputMode,
    pub username_input: String,
    pub password_input: String,
    pub focused_field: usize, 
    pub token: Option<String>,
    pub emails: Vec<crate::models::SentEmail>,
    pub sent_emails: Vec<crate::models::SentEmail>,
    pub table_state: ratatui::widgets::TableState,
    pub error_message: Option<String>,
    
    // --- NUEVOS CAMPOS ---
    pub to_input: String,
    pub subject_input: String,
    pub body_input: String,
    pub selected_email_body: Option<String>,

    pub confirm_password_input: String, // Nuevo campo
    pub success_message: Option<String>, // Para mostrar mensajes de éxito en registro
}

impl App {
    pub fn new() -> Self {
        let mut table_state = ratatui::widgets::TableState::default();
        table_state.select(Some(0));
        
        Self {
            current_screen: CurrentScreen::Login,
            input_mode: InputMode::Editing,
            username_input: String::new(),
            password_input: String::new(),
            focused_field: 0,
            token: None,
            emails: Vec::new(),
            sent_emails: Vec::new(),
            table_state,
            error_message: None,
            // Inicialización de nuevos campos
            to_input: String::new(),
            subject_input: String::new(),
            body_input: String::new(),
            selected_email_body: None,

            confirm_password_input: String::new(),
            success_message: None,
        }
    }

    // --- MÉTODOS DE NAVEGACIÓN ---
    pub fn next_email(&mut self) {
        if self.emails.is_empty() { return; }
        let i = match self.table_state.selected() {
            Some(i) => if i >= self.emails.len() - 1 { 0 } else { i + 1 },
            None => 0,
        };
        self.table_state.select(Some(i));
    }

    pub fn previous_email(&mut self) {
        if self.emails.is_empty() { return; }
        let i = match self.table_state.selected() {
            Some(i) => if i == 0 { self.emails.len() - 1 } else { i - 1 },
            None => 0,
        };
        self.table_state.select(Some(i));
    }

    // Útil para cuando cambias de pantalla y quieres resetear los inputs
    pub fn reset_compose(&mut self) {
        self.to_input.clear();
        self.subject_input.clear();
        self.body_input.clear();
        self.focused_field = 0;
    }

    pub fn reset_register(&mut self) {
        self.username_input.clear();
        self.password_input.clear();
        self.confirm_password_input.clear();
        self.focused_field = 0;
        self.error_message = None;
    }
}