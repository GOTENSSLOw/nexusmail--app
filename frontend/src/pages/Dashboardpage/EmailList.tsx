import { EmailRow } from './EmailRow';
import { EmailType } from './Dashboard';

interface EmailListProps {
    emails: EmailType[];
}

export const EmailList = ({ emails }: EmailListProps) => {
    return (
        <div className="email-list">
            {emails.map((email) => (
                <EmailRow key={email.id} email={email} />
            ))}
            
            {emails.length === 0 && (
                <div className="email-row" style={{ justifyContent: 'center', color: '#666' }}>
                    No se encontraron correos.
                </div>
            )}
        </div>
    );
};