import './Dashboard.css';
import { EmailList } from './EmailList'; 

export interface EmailType {
    id: number;
    sender: string;
    subject: string;
    snippet: string;
    time: string;
    unread: boolean;
}

const mockEmails: EmailType[] = [
  { id: 1, sender: "Stripe Support", subject: "Action required: Verify your email address", snippet: "Please confirm your email address to continue using your Stripe account...", time: "10:30 AM", unread: true },
  { id: 2, sender: "GitHub Notifications", subject: "[GitHub] A first-party App has been added", snippet: "You're receiving this email because a new application was authorized...", time: "Yesterday", unread: false },
  { id: 3, sender: "Linear Team", subject: "New features in Linear: Cycles & Projects", snippet: "We've just released a major update to how we handle project planning...", time: "Mar 12", unread: true }
];

export const Dashboard = () => {
    return (
        <main className="main-content">
            <header className="top-header">
                <input type="text" placeholder="Buscar correos..." className="search-bar"/>
            </header>

            <EmailList emails={mockEmails} />
        </main>
    );
};