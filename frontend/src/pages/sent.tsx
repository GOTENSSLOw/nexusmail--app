import { useState, useEffect } from 'react';
import { EmailList } from './Dashboardpage/EmailList';
import { EmailViewer } from './Dashboardpage/EmailViewer';
import { EmailType } from './Dashboardpage/Dashboard';
import { useAuth } from '../context/AuthContext';
import { fetchEmails } from '../services/api';
import './Dashboardpage/dashboard.css';

export const Sent = () => {
    const { username, password } = useAuth();
    const [emails, setEmails] = useState<EmailType[]>([]);
    const [busqueda, setBusqueda] = useState<string>('');
    const [loading, setLoading] = useState(true);
    const [selectedEmail, setSelectedEmail] = useState<EmailType | null>(null);

    useEffect(() => {
        if (!username || !password) return;
        fetchEmails(username, password)
            .then((data) => {
                const userEmail = `${username}@lan.local`;
                const mapped: EmailType[] = data
                    .filter((e: any) => e.recipient !== userEmail)
                    .map((e: any) => ({
                        id: e.id,
                        sender: `Para: ${e.recipient}`,
                        subject: e.subject,
                        snippet: e.snippet,
                        body: e.body,
                        time: e.time,
                        unread: e.unread,
                    }));
                setEmails(mapped);
            })
            .catch(() => {})
            .finally(() => setLoading(false));
    }, [username, password]);

    const correosFiltrados = emails.filter((correo) =>
        correo.subject.toLowerCase().includes(busqueda.toLowerCase()) ||
        correo.snippet.toLowerCase().includes(busqueda.toLowerCase()) ||
        correo.sender.toLowerCase().includes(busqueda.toLowerCase())
    );

    if (loading) return <main className="main-content"><p>Cargando enviados...</p></main>;

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
