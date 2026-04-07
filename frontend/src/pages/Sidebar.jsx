import { FiEdit, FiInbox, FiSettings, FiLogOut } from 'react-icons/fi';
import { useNavigate, Link, useLocation } from 'react-router-dom';

export const Sidebar = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const correosSinLeer = 2; 

    return (
        <aside className="sidebar">
            <div className="sidebar-logo">
                <h1>NexusMail</h1>
            </div>
            <button className="btn-compose"> <FiEdit /> Compose</button>

            <nav className="sidebar-menu">
                <Link to="/inbox" className={location.pathname === '/inbox' ? 'active' : ''}>
                    <FiInbox /> Bandeja de entrada <span className="badge">{correosSinLeer}</span>
                </Link>
                <a href="/recibidos"><FiInbox /> Recibidos <span className="badge"> 5</span></a>
                
                <a href="/enviados"><FiEdit /> Enviados</a>
                
                <Link to="/settings" className={location.pathname === '/settings' ? 'active' : ''}>
                    <FiSettings /> Configuración de cuenta
                </Link>
            </nav>
            <div className="sidebar-footer">
                <button className="btn-logout" onClick={() => navigate('/login')}><FiLogOut /> Cerrar sesión</button>
            </div>
        </aside>
    );
};