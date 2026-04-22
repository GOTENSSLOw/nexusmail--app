import "./dashboard.css";
import { useState, useEffect } from 'react';
import { EmailList } from './EmailList';
import { EmailViewer } from './EmailViewer';
import { useAuth } from '../../context/AuthContext';
import { fetchEmails } from '../../services/api';

export interface EmailType {
    id: number;
    sender: string;
    subject: string;
    snippet: string;
    body: string;
    time: string;
    unread: boolean;
}

export const Dashboard = () => {
    const { username, password } = useAuth();
    const [emails, setEmails] = useState<EmailType[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [selectedEmail, setSelectedEmail] = useState<EmailType | null>(null);
    const [busqueda, setBusqueda] = useState('');

    useEffect(() => {
        if (!username || !password) return;
        setLoading(true);
        fetchEmails(username, password)
            .then((data) => {
                const userEmail = `${username}@lan.local`;
                const mapped: EmailType[] = data
                    .filter((e: any) => e.recipient === userEmail)
                    .map((e: any) => ({
                        id: e.id,
                        sender: e.sender,
                        subject: e.subject,
                        snippet: e.snippet,
                        body: e.body,
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

    const correosFiltrados = emails.filter((e) =>
        e.subject.toLowerCase().includes(busqueda.toLowerCase()) ||
        e.snippet.toLowerCase().includes(busqueda.toLowerCase()) ||
        e.sender.toLowerCase().includes(busqueda.toLowerCase())
    );

    return (
        <main className="main-content">
            <header className="top-header">
                <input
                    type="text"
                    placeholder="Buscar correos..."
                    className="search-bar"
                    value={busqueda}
                    onChange={(e) => setBusqueda(e.target.value)}
                />
            </header>
            <div className={`inbox-layout${selectedEmail ? ' inbox-layout--split' : ''}`}>
                <EmailList
                    emails={correosFiltrados}
                    selectedId={selectedEmail?.id ?? null}
                    onSelect={setSelectedEmail}
                />
                {selectedEmail && (
                    <EmailViewer
                        email={selectedEmail}
                        onClose={() => setSelectedEmail(null)}
                    />
                )}
            </div>
        </main>
    );
};
