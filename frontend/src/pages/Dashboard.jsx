import './Dashboard.css';
import { useState } from 'react';
import { Sidebar } from './Sidebar'; // ¡Nuevo! Importamos a tu hijo Sidebar

const mockEmails = [
  { 
    id: 1, 
    sender: "Stripe Support", 
    subject: "Action required: Verify your email address", 
    snippet: "Please confirm your email address to continue using your Stripe account...", 
    time: "10:30 AM", 
    unread: true 
  },
  { 
    id: 2, 
    sender: "GitHub Notifications", 
    subject: "[GitHub] A first-party App has been added", 
    snippet: "You're receiving this email because a new application was authorized...", 
    time: "Yesterday", 
    unread: false 
  },
  { 
    id: 3, 
    sender: "Linear Team", 
    subject: "New features in Linear: Cycles & Projects", 
    snippet: "We've just released a major update to how we handle project planning...", 
    time: "Mar 12", 
    unread: true 
  }
];

export const Dashboard = () => {
    // Calculamos los correos y preparamos el cerebro del modal
    const correosSinLeer = mockEmails.filter(correo => correo.unread === true).length;
    const [isModalOpen, setIsModalOpen] = useState(false);

    return (
        <div className="dashboard-container">    
            
            {/* 2. LA MAGIA: Le pasamos al Sidebar el control del modal y el número de correos */}
            <Sidebar 
                abrirModal={() => setIsModalOpen(true)} 
                cantidadCorreos={correosSinLeer}
            />

            <main className="main-content">
                <header className="top-header">
                    <input type="text" placeholder="escribe un mensaje..." className="search-bar"/>
                </header>

                <div className="email-list">
                    {mockEmails.map((email) => (
                        <div key={email.id} className="email-row">
                            <div className="email-sender">{email.sender}</div>
                            <div className="email-content">
                                <span className="email-subject"> {email.subject} </span>
                                <span className="email-snippet"> - {email.snippet} </span>
                            </div>
                            <div className="email-time">{email.time}</div>
                        </div>
                    ))}
                </div>
            </main>

            {/* 3. El modal se queda exactamente igual */}
            {isModalOpen && (
                <div className="modal-overlay">
                    <div className="modal-content">
                        <div className="modal-header">
                            <h3>New Message</h3>
                            <button className="btn-close" onClick={() => setIsModalOpen(false)}>X</button>
                        </div>
                        
                        <div className="modal-body">
                            <input type="text" placeholder="To" className="modal-input" />
                            <input type="text" placeholder="Subject" className="modal-input" />
                            <textarea placeholder="Write your message..." className="modal-textarea"></textarea>
                        </div>
                        
                        <div className="modal-footer">
                            <button className="btn-send">Send</button>
                        </div>
                    </div>
                </div>
            )}
        </div> 
        
    );
};