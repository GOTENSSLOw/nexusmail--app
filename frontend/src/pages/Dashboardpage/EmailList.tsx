import { EmailRow } from './EmailRow';
import { EmailType } from './Dashboard';

interface EmailListProps {
    emails: EmailType[];
    selectedId: number | null;
    onSelect: (email: EmailType) => void;
}

export const EmailList = ({ emails, selectedId, onSelect }: EmailListProps) => {
    return (
        <div className="email-list">
            {emails.map((email) => (
                <EmailRow
                    key={email.id}
                    email={email}
                    isSelected={email.id === selectedId}
                    onSelect={onSelect}
                />
            ))}
            
            {emails.length === 0 && (
                <div className="email-row" style={{ justifyContent: 'center', color: '#666' }}>
                    No se encontraron correos.
                </div>
            )}
        </div>
    );
};