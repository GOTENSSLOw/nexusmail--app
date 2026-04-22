import { useAuth } from '../../context/AuthContext';

const USER_DISPLAY_NAMES: Record<string, string> = {
    user1: 'User1',
    user2: 'User2',
    user3: 'User3',
};

export const ProfileBanner = () => {
    const { username } = useAuth();
    const displayName = USER_DISPLAY_NAMES[username ?? ''] ?? username ?? 'Usuario';
    const email = username ? `${username}@lan.local` : '';

    return (
        <div className="card profile-banner-card">
            <div className="banner-background"></div>
            <div className="banner-info">
                <div className="profile-avatar-container">
                    <div className="avatar-placeholder">
                        <span className="avatar-initial">{displayName.charAt(0).toUpperCase()}</span>
                    </div>
                </div>
                <div className="profile-details">
                    <h2>{displayName}</h2>
                    <p>Cuenta personal • {email}</p>
                </div>
                <button className="btn-primary">Editar perfil</button>
            </div>
        </div>
    );
};