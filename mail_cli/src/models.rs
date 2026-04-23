use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize, Debug, Clone)]
pub struct SentEmail {
    pub id: i32,
    pub sender: String,    // AÑADIDO: Fundamental para la bandeja de entrada
    pub recipient: String, // En 'Sent' verás esto, en 'Inbox' verás tu propia dirección
    pub subject: String,
    pub snippet: String,
    pub body: String,  
    pub time: String,
    pub unread: bool,
}

#[derive(Deserialize, Serialize)]
pub struct EmailPayload {
    pub to: String,
    pub subject: String,
    pub body: String,
}

#[derive(Serialize, Deserialize)]
pub struct NewUser {
    pub username: String,
    pub password: String,
}

#[derive(Deserialize)]
pub struct TokenResponse {
    pub access: String,
    pub refresh: String,
}