import { useState, useEffect, useCallback } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { ComposeModal } from './ComposeModal';
import { useAuth } from '../context/AuthContext';
import { fetchEmails } from '../services/api';
import './Dashboardpage/dashboard.css';

export const Layout = () => {
    const [isModalOpen, setIsModalOpen] = useState(false);
    const { username, password } = useAuth();
    const [unreadCount, setUnreadCount] = useState(0);

    const loadUnreadCount = useCallback(() => {
        if (!username || !password) return;
        fetchEmails(username, password)
            .then((data) => {
                const count = data.filter((e) => e.unread).length;
                setUnreadCount(count);
            })
            .catch(() => {});
    }, [username, password]);

    useEffect(() => {
        loadUnreadCount();
    }, [loadUnreadCount]);

    return (
        <div className="dashboard-container">
            <Sidebar
                abrirModal={() => setIsModalOpen(true)}
                cantidadCorreos={unreadCount}
            />

            <Outlet />

            {isModalOpen && (
                <ComposeModal cerrarModal={() => { setIsModalOpen(false); loadUnreadCount(); }} />
            )}
        </div>
    );
};
