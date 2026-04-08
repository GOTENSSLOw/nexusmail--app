export const SecuritySettings = () => (
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
);