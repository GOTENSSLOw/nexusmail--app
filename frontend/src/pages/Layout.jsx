import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { ComposeModal } from './ComposeModal'; 
import './Dashboardpage/Dashboard.css';

export const Layout = () => {
    const [isModalOpen, setIsModalOpen] = useState(false);
    const cantidadCorreos = 2; 

    return (
        <div className="dashboard-container"> 
            <Sidebar 
                abrirModal={() => setIsModalOpen(true)} 
                cantidadCorreos={cantidadCorreos}
            />
            
            <Outlet /> 

            {isModalOpen && (
                <ComposeModal cerrarModal={() => setIsModalOpen(false)} />
            )}
        </div>
    );
};