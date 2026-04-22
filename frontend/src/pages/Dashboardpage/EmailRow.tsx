import { EmailType } from './Dashboard';

interface EmailRowProps {
    email: EmailType;
    isSelected: boolean;
    onSelect: (email: EmailType) => void;
}

export const EmailRow = ({ email, isSelected, onSelect }: EmailRowProps) => {
    return (
        <div
            className={`email-row${isSelected ? ' email-row--selected' : ''}${email.unread ? ' email-row--unread' : ''}`}
            onClick={() => onSelect(email)}
        >
            <div className="email-sender">{email.sender}</div>
            <div className="email-content">
                <span className="email-subject">{email.subject}</span>
                <span className="email-snippet"> — {email.snippet}</span>
            </div>
            <div className="email-time">{email.time}</div>
        </div>
    );
};