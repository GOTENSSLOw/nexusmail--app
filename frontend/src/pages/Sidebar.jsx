import { FiEdit, FiInbox, FiSettings, FiLogOut } from 'react-icons/fi';
import { useNavigate, Link, useLocation } from 'react-router-dom';

// 1. RECIBIMOS LAS PROPS DEL PADRE EN LOS PARÁMETROS
export const Sidebar = ({ abrirModal, cantidadCorreos }) => {
    const navigate = useNavigate();
    const location = useLocation();

    return (
        <aside className="sidebar">
            <div className="sidebar-logo">
                <h1>NexusMail</h1>
            </div>
            
            {/* 2. CONECTAMOS EL BOTÓN AL CONTROL REMOTO DEL PADRE */}
            <button className="btn-compose" onClick={abrirModal}>
                <FiEdit /> Compose
            </button>

            <nav className="sidebar-menu">
                <Link to="/inbox" className={location.pathname === '/inbox' ? 'active' : ''}>
                    {/* 3. MOSTRAMOS EL NÚMERO REAL DE CORREOS SIN LEER */}
                    <FiInbox /> Bandeja de entrada <span className="badge">{cantidadCorreos}</span>
                </Link>
                
                <Link to="/sent" className={location.pathname === '/sent' ? 'active' : ''}>
                    <FiEdit /> Enviados
                </Link>
                
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