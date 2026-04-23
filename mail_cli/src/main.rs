    use clap::{Parser, Subcommand};

    mod services;
    mod models;
    mod tui;

    #[derive(Parser)]
    #[command(name = "BacanalMail")]
    #[command(about = "CLI para probar la API de correo sin depender del frontend", long_about = None)]
    struct Cli {
        #[command(subcommand)]
        command: Commands,
    }

    #[derive(Subcommand)]
    enum Commands {
        /// Lista los correos de un usuario
        Inbox {
            username: String,
            #[arg(short, long)]
            password: String,
        },

        /// Lista los correos enviados de un usuario
        Sent {
            username: String,
            #[arg(short, long)]
            password: String,
        },

        /// Envía un correo nuevo
        Send {
            sender: String,
            to: String,
            subject: String,
            body: String,
        },

        CreateUser {
            username: String,
            #[arg(short, long)]
            password: String,
        },

        Tui {
        },
    }



    #[tokio::main]
    async fn main() -> Result<(), Box<dyn std::error::Error>> {
        let cli = Cli::parse();

        match &cli.command {
            Commands::Inbox { username, password } => {
                // 1. Obtenemos el token primero
                let token = services::login(username, password).await?;
                // 2. Usamos el token y el password para el polling
                services::fetch_inbox(&token).await?;
            }

            Commands::Sent { username, password } => {
                let token = services::login(username, password).await?;
                services::fetch_sent_data(&token).await?;
            }
            
            Commands::Send { sender, to, subject, body } => {
                // Nota: Aquí necesitaríamos el password del sender para obtener el token. 
                // Podrías añadir un argumento --password al comando Send o pedirlo interactivamente.
                // Por simplicidad, asumamos que por ahora usas la TUI para enviar si quieres seguridad JWT completa.
                println!("⚠️ El comando 'send' ahora requiere autenticación. Usa la TUI o añade el login aquí.");
            }

            Commands::CreateUser { username, password } => {
                // Este sigue igual porque es público
                services::create_user(username, password).await?;
            }

            Commands::Tui {} => {
                tui::run_tui().await?; 
            }
        }
        
        Ok(())
    }