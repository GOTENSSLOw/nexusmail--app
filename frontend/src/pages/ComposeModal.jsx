import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { sendEmail } from '../services/api';

export const ComposeModal = ({ cerrarModal }) => {
    const { username } = useAuth();
    const [to, setTo] = useState('');
    const [subject, setSubject] = useState('');
    const [body, setBody] = useState('');
    const [sending, setSending] = useState(false);
    const [result, setResult] = useState('');

    const handleSend = async () => {
        if (!to || !subject || !body) {
            setResult('Todos los campos son obligatorios');
            return;
        }
        setSending(true);
        setResult('');
        try {
            await sendEmail(username, to, subject, body);
            setResult('Correo enviado');
            setTimeout(cerrarModal, 1000);
        } catch (err) {
            setResult('Error: ' + err.message);
        } finally {
            setSending(false);
        }
    };

    return (
        <div className="modal-overlay">
            <div className="modal-content">
                <div className="modal-header">
                    <h3>New Message</h3>
                    <button className="btn-close" onClick={cerrarModal}>X</button>
                </div>

                <div className="modal-body">
                    <input type="text" placeholder="To" className="modal-input" value={to} onChange={(e) => setTo(e.target.value)} />
                    <input type="text" placeholder="Subject" className="modal-input" value={subject} onChange={(e) => setSubject(e.target.value)} />
                    <textarea placeholder="Write your message..." className="modal-textarea" value={body} onChange={(e) => setBody(e.target.value)} />
                </div>

                <div className="modal-footer">
                    {result && <span style={{marginRight: '10px', color: result.includes('Error') ? 'red' : 'green'}}>{result}</span>}
                    <button className="btn-send" onClick={handleSend} disabled={sending}>
                        {sending ? 'Enviando...' : 'Send'}
                    </button>
                </div>
            </div>
        </div>
    );
};
