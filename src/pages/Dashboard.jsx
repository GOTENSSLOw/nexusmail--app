import { FiInbox } from 'react-icons/fi';
import Dashboard from '../pages/Dashboard.css';

const mockEmails = [
  { id: 1, sender: "Stripe Support", 
    subject: "Action required: Verify your email address", 
    snippet: "Please confirm your email address to continue using your Stripe account...", 
    time: "10:30 AM", 
    unread: true },
  { id: 2, 
    sender: "GitHub Notifications", 
    subject: "[GitHub] A first-party App has been added", 
    snippet: "You're receiving this email because a new application was authorized...", 
    time: "Yesterday", 
    unread: false },
  { id: 3, 
    sender: "Linear Team", 
    subject: "New features in Linear: Cycles & Projects", 
    snippet: "We've just released a major update to how we handle project planning...", 
    time: "Mar 12", 
    unread: true }
];

export const Dashboard = () => {
    return (
        // Conservamos la clase main-content
        <main className="main-content">
            <header className="top-header">
                <input type="text" placeholder="escribe un mensaje..." className="search-bar"/>
                <div className="header-icons">
                    <span><FiInbox /></span>
                </div>
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
    );
};