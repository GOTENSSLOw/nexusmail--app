export const ProfileBanner = () => (
    <div className="card profile-banner-card">
        <div className="banner-background"></div>
        <div className="banner-info">
            <div className="profile-avatar-container">
                <div className="avatar-placeholder">
                    <img src="/rossman.png" alt="Perfil" />
                </div>
            </div>
            <div className="profile-details">
                <h2>Rossman Fuentes</h2>
                <p>Cuenta personal • rossman1234@nexusmail.com</p>
            </div>
            <button className="btn-primary">Editar perfil</button>
        </div>
    </div>
);