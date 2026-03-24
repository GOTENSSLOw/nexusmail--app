import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import '../pages/Dashboard.css';

export const Layout = () => {
    return (
        <div className="dashboard-container"> 
            <Sidebar />
            <Outlet /> 
        </div>
    );
};