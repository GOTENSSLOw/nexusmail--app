import { useState } from 'react';
import { EmailList } from './EmailList'; 
import { EmailType } from './Dashboard';
import './Dashboard.css';

const mockSentEmails: EmailType[] = [
  { 
    id: 1, 
    sender: "Para: Stripe Support", 
    subject: "Re: Action required: Verify your email address", 
    snippet: "Hola, ya envié los documentos solicitados para verificar mi cuenta. Saludos, Rossman.", 
    time: "11:15 AM", 
    unread: false 
  },
  { 
    id: 2, 
    sender: "Para: Equipo Debita", 
    subject: "Avance del frontend en React", 
    snippet: "Les adjunto mi parte del código. Avisen cuando el backend en Rust esté listo para conectarlo. Atte: Rossman.", 
    time: "Ayer", 
    unread: false 
  },
  { 
    id: 3, 
    sender: "Para: Linear Team", 
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
        correo.sender.toLowerCase().includes(busqueda.toLowerCase())
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

            <EmailList emails={correosFiltrados} />
            
        </main>
    );
};