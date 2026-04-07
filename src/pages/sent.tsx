import { useState } from 'react';
import './Dashboard.css';

interface SentEmail {
  id: number;
  recipient: string;
  subject: string;
  snippet: string;
  time: string;
  unread: boolean;
}

const mockSentEmails: SentEmail[] = [
  { 
    id: 1, 
    recipient: "Para: Stripe Support", 
    subject: "Re: Action required: Verify your email address", 
    snippet: "Hola, ya envié los documentos solicitados para verificar mi cuenta. Saludos, Rossman.", 
    time: "11:15 AM", 
    unread: false 
  },
  { 
    id: 2, 
    recipient: "Para: Equipo Debita", 
    subject: "Avance del frontend en React", 
    snippet: "Les adjunto mi parte del código. Avisen cuando el backend en Rust esté listo para conectarlo. Atte: Rossman.", 
    time: "Ayer", 
    unread: false 
  },
  { 
    id: 3, 
    recipient: "Para: Linear Team", 
    subject: "Feedback on new features", 
    snippet: "La nueva actualización de Cycles está excelente. ¿Tienen planeado añadir más integraciones pronto? - Rossman", 
    time: "Mar 12", 
    unread: false 
  }
];

export const Sent = () => {
    const [busqueda, setBusqueda] = useState<string>('');

    const correosFiltrados = mockSentEmails.filter((correo) => 
        correo.subject.toLowerCase().includes(busqueda.toLowerCase()) ||
        correo.snippet.toLowerCase().includes(busqueda.toLowerCase()) ||
        correo.recipient.toLowerCase().includes(busqueda.toLowerCase())
    );

    return (
        <main className="main-content">
            <header className="top-header">
                <input 
                    type="text" 
                    placeholder="Buscar en enviados..." 
                    className="search-bar"
                    value={busqueda}
                    onChange={(e) => setBusqueda(e.target.value)}
                />
            </header>

            <div className="email-list">
                {correosFiltrados.map((email) => (
                    <div key={email.id} className="email-row">
                        <div className="email-sender">{email.recipient}</div>
                        <div className="email-content">
                            <span className="email-subject"> {email.subject} </span>
                            <span className="email-snippet"> - {email.snippet} </span>
                        </div>
                        <div className="email-time">{email.time}</div>
                    </div>
                ))}
                
                {correosFiltrados.length === 0 && (
                    <div className="email-row" style={{ justifyContent: 'center', color: '#666' }}>
                        No se encontraron correos que coincidan con tu búsqueda.
                    </div>
                )}
            </div>
        </main>
    );
};