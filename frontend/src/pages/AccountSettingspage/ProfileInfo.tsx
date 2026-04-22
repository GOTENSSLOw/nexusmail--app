import { useAuth } from '../../context/AuthContext';

const USER_DISPLAY_NAMES: Record<string, string> = {
    user1: 'User1',
    user2: 'User2',
    user3: 'User3',
};

export const ProfileInfo = () => {
    const { username } = useAuth();
    const displayName = USER_DISPLAY_NAMES[username ?? ''] ?? username ?? 'Usuario';
    const email = username ? `${username}@lan.local` : '';

    return (
        <div className="card info-card">
            <h3>👤 Información de perfil</h3>
            <div className="info-grid">
                <div className="info-item">
                    <span>NOMBRE COMPLETO</span>
                    <p>{displayName}</p>
                </div>
                <div className="info-item">
                    <span>CORREO ELECTRÓNICO</span>
                    <p>{email}</p>
                </div>
                <div className="info-item">
                    <span>NÚMERO DE TELÉFONO</span>
                    <p>+505 7848 5278</p>
                </div>
                <div className="info-item">
                    <span>ZONA HORARIA</span>
                    <p>CST (GMT-6)</p>
                </div>
            </div>
        </div>
    );
};