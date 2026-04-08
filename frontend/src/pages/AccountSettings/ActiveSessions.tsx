export const ActiveSessions = () => (
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
);