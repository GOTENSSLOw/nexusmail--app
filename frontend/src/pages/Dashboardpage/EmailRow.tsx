import { EmailType } from './Dashboard';

interface EmailRowProps {
    email: EmailType;
}

export const EmailRow = ({ email }: EmailRowProps) => {
    return (
        <div className="email-row">
            <div className="email-sender">{email.sender}</div>
            <div className="email-content">
                <span className="email-subject"> {email.subject} </span>
                <span className="email-snippet"> - {email.snippet} </span>
            </div>
            <div className="email-time">{email.time}</div>
        </div>
    );
};