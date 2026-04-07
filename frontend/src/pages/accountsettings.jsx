import "./accountsetting.css";  

export const AccountSettings = () => {
    return (
        <main className="main-content accountsettings-container">
            <div className="accountsettings-header">
                <h1>Configuración de cuenta</h1>
                <div className="header-search">
                    <input type="text" placeholder="Buscar en ajustes..." className="search-bar"/>
                </div>
            </div>

            <div className="settings-content">

                {/* Banner de Perfil Principal */}
                <div className="card profile-banner-card">
                    <div className="banner-background"></div>
                    <div className="banner-info">
                        <div className="profile-avatar-container">
                            <div className="avatar-placeholder">
                                <img src="./rossman.png" alt="Perfil" />
                            </div>
                        </div>
                        <div className="profile-details">
                            <h2>Rossman Fuentes</h2>
                            <p>Cuenta personal • rossman1234@nexusmail.com</p>
                        </div>
                        <button className="btn-primary">Editar perfil</button>
                    </div>
                </div>

                {/* Contenedor Grid para las secciones de abajo */}
                <div className="settings-grid">
                    
                    {/* Columna Izquierda (Más ancha) */}
                    <div className="grid-left">
                        {/* Información de Perfil */}
                        <div className="card info-card">
                            <h3>👤 Información de perfil</h3>
                            <div className="info-grid">
                                <div className="info-item">
                                    <span>NOMBRE COMPLETO</span>
                                    <p>Rossman Fuentes</p>
                                </div>
                                <div className="info-item">
                                    <span>CORREO ELECTRÓNICO</span>
                                    <p>rossman1234@nexusmail.com</p>
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

                        {/* Sesiones Activas */}
                        <div className="card sessions-card">
                            <div className="card-header-flex">
                                <h3>💻 Sesiones Activas</h3>
                                <a href="#" className="text-link">Cerrar sesión en todos los demás dispositivos</a>
                            </div>
                            <div className="session-list">
                                <div className="session-item">
                                    <div className="session-icon">💻</div>
                                    <div className="session-info">
                                        <div className="session-title-row">
                                            <h4>Windows 11 <span className="badge-current">SESIÓN ACTUAL</span></h4>
                                            <span className="time-ago">Ahora</span>
                                        </div>
                                        <p>Chinandega, NI • IP: 187.134.22.105</p>
                                    </div>
                                </div>
                                <hr />
                                <div className="session-item">
                                    <div className="session-icon">📱</div>
                                    <div className="session-info">
                                        <div className="session-title-row">
                                            <h4>Infinix Note 10</h4>
                                            <span className="time-ago">Última actividad: hace 2 horas</span>
                                        </div>
                                        <p>Chinandega, NI • IP: 189.203.45.12</p>
                                    </div>
                                    <button className="btn-text-danger">Revocar</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Columna Derecha (Más estrecha) */}
                    <div className="grid-right">
                        {/* Seguridad */}
                        <div className="card security-card">
                            <h3>🛡️ Seguridad</h3>
                            <ul className="security-list">
                                <li>
                                    <div className="sec-item-info">
                                        <h4>Cambiar contraseña</h4>
                                        <p>Último cambio hace 3 meses</p>
                                    </div>
                                    <span className="arrow">&gt;</span>
                                </li>
                                <li>
                                    <div className="sec-item-info">
                                        <h4>Autenticación 2FA <span className="dot-active"></span></h4>
                                        <p>Habilitado actualmente vía App</p>
                                    </div>
                                    <span className="arrow">&gt;</span>
                                </li>
                                <li>
                                    <div className="sec-item-info">
                                        <h4>Claves de seguridad</h4>
                                        <p>Añadir hardware FIDO físico</p>
                                    </div>
                                    <button className="btn-icon-add">+</button>
                                </li>
                            </ul>
                        </div>

                        {/* Plan Pro */}
                        <div className="card pro-plan-card">
                            <h4 className="pro-title">PLAN PRO ACTIVO</h4>
                            <p>Estás usando 45GB de 100GB. Tu próxima fecha de facturación es el 1 de diciembre.</p>
                            <button className="btn-secondary">Gestionar suscripción</button>
                        </div>
                    </div>

                </div>
            </div>
        </main>
    );
};