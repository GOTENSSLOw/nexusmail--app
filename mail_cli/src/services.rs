use prettytable::{Table, format, row};

use crate::models::{SentEmail, NewUser, TokenResponse};
const BASE_URL: &str = "http://localhost:8000/api";

// 1. LOGIN: Sigue igual, pero ahora el backend aprovecha para guardar la clave
pub async fn login(username: &str, password: &str) -> Result<String, Box<dyn std::error::Error>> {
    let url = format!("{}/login/", BASE_URL);
    let client = reqwest::Client::new();

    let res = client.post(&url)
        .json(&serde_json::json!({
            "username": username,
            "password": password
        }))
        .send()
        .await?;

    if res.status().is_success() {
        let tokens: TokenResponse = res.json().await?;
        Ok(tokens.access) 
    } else {
        Err("Credenciales inválidas".into())
    }
}

// 2. FETCH DATA: ¡Aquí está el gran cambio! Ya no pide 'password'
pub async fn fetch_inbox_data(token: &str) -> Result<Vec<SentEmail>, Box<dyn std::error::Error>> {
    let url = format!("{}/read-emails/me/", BASE_URL);
    let client = reqwest::Client::new();
    
    let res = client.get(&url)
        .header("Authorization", format!("Bearer {}", token))
        // ELIMINADO: .query(&[("password", password)]) 
        // El servidor ya tiene la clave en UserProfile
        .send()
        .await?;

    if res.status().is_success() {
        let emails: Vec<SentEmail> = res.json().await?;
        Ok(emails)
    } else {
        let err_body: serde_json::Value = res.json().await?;
        let msg = err_body["error"].as_str().unwrap_or("Error desconocido");
        Err(msg.into())
    }
}

// 3. SEND EMAIL: Se mantiene igual (ya usaba solo el Token)
pub async fn send_email(token: &str, to: &str, subject: &str, body: &str) -> Result<(), Box<dyn std::error::Error>> {
    let url = format!("{}/send-email/", BASE_URL);
    let client = reqwest::Client::new();
    
    let payload = serde_json::json!({
        "to": to,
        "subject": subject,
        "body": body,
    });

    let res = client.post(&url)
        .header("Authorization", format!("Bearer {}", token))
        .json(&payload)
        .send()
        .await?;

    if res.status().is_success() {
        Ok(()) // Retornamos Ok para que el handler sepa que terminó bien
    } else {
        Err("Error al enviar el correo".into())
    }
}

// 4. CREATE USER: Se mantiene igual
pub async fn create_user(username: &str, password: &str) -> Result<(), Box<dyn std::error::Error>> {
    let url = format!("{}/register/", BASE_URL);
    let client = reqwest::Client::new();
    
    let payload = NewUser {
        username: username.into(),
        password: password.into(),
    };

    let res = client.post(&url).json(&payload).send().await?;

    if res.status().is_success() {
        Ok(())
    } else {
        let error_body: serde_json::Value = res.json().await?;
        let msg = error_body["error"].as_str().unwrap_or("Error desconocido");
        Err(msg.into())
    }
}

pub async fn fetch_inbox(token: &str) -> Result<(), Box<dyn std::error::Error>> {
    // CORRECCIÓN: Antes solo pasabas 'token', ahora pasas ambos
    let emails = fetch_inbox_data(token).await?; 
    
    let mut table = Table::new();
    table.set_format(*format::consts::FORMAT_NO_BORDER_LINE_SEPARATOR);
    table.set_titles(row!["ID", "PARA", "ASUNTO", "RESUMEN", "LEÍDO"]);

    for e in emails {
        let read_status = if e.unread { "✕" } else { "✓" };
        table.add_row(row![e.id, e.recipient, e.subject, e.snippet, read_status]);
    }
    table.printstd();
    Ok(())
}


pub async fn fetch_sent_data(token: &str) -> Result<Vec<SentEmail>, Box<dyn std::error::Error>> {
    // Asumiendo que creas este endpoint en Django (ej: /api/read-emails/sent/)
    let url = format!("{}/read-emails/sent/", BASE_URL);
    let client = reqwest::Client::new();
    
    let res = client.get(&url)
        .header("Authorization", format!("Bearer {}", token)) 
        .send()
        .await?;

    if res.status().is_success() {
        let emails: Vec<SentEmail> = res.json().await?;
        Ok(emails)
    } else {
        Err("Error al obtener correos enviados".into())
    }
}