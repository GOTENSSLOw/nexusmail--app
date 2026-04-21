import "./dashboard.css";
import { useState, useEffect } from 'react';
import { EmailList } from './EmailList';
import { useAuth } from '../../context/AuthContext';
import { fetchEmails } from '../../services/api';

export interface EmailType {
    id: number;
    sender: string;
    subject: string;
    snippet: string;
    time: string;
    unread: boolean;
}

export const Dashboard = () => {
    const { username, password } = useAuth();
    const [emails, setEmails] = useState<EmailType[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        if (!username || !password) return;
        setLoading(true);
        fetchEmails(username, password)
            .then((data) => {
                const mapped: EmailType[] = data.map((e: any) => ({
                    id: e.id,
                    sender: e.recipient,
                    subject: e.subject,
                    snippet: e.snippet,
                    time: e.time,
                    unread: e.unread,
                }));
                setEmails(mapped);
            })
            .catch((err) => setError(err.message))
            .finally(() => setLoading(false));
    }, [username, password]);

    if (loading) return <main className="main-content"><p>Cargando correos...</p></main>;
    if (error) return <main className="main-content"><p style={{color:'red'}}>{error}</p></main>;

    return (
        <main className="main-content">
            <header className="top-header">
                <input type="text" placeholder="Buscar correos..." className="search-bar"/>
            </header>
            <EmailList emails={emails} />
        </main>
    );
};
