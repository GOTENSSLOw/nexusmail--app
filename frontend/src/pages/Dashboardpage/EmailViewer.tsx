import { EmailType } from './Dashboard';

interface EmailViewerProps {
    email: EmailType;
    onClose: () => void;
}

export const EmailViewer = ({ email, onClose }: EmailViewerProps) => {
    return (
        <div className="email-viewer">
            <div className="email-viewer-header">
                <div className="email-viewer-meta">
                    <h2 className="email-viewer-subject">{email.subject}</h2>
                    <div className="email-viewer-details">
                        <span className="email-viewer-sender">
                            <strong>De:</strong> {email.sender}
                        </span>
                        <span className="email-viewer-time">{email.time}</span>
                    </div>
                </div>
                <button className="btn-close-viewer" onClick={onClose} title="Cerrar correo">
                    ✕
                </button>
            </div>
            <div className="email-viewer-body">
                {email.body
                    ? email.body.split('\n').map((line, i) => (
                        <p key={i}>{line || <br />}</p>
                    ))
                    : <p className="email-viewer-no-body">Sin contenido.</p>
                }
            </div>
        </div>
    );
};
