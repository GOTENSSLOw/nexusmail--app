import "./accountsetting.css";  
import { ProfileBanner } from "./AccountSettings/ProfileBanner";
import { ProfileInfo } from "./AccountSettings/ProfileInfo";
import { ActiveSessions } from "./AccountSettings/ActiveSessions";
import { SecuritySettings } from "./AccountSettings/SecuritySettings";
import { PlanCard } from "./AccountSettings/PlanCard";

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
                <ProfileBanner />

                <div className="settings-grid">
                    <div className="grid-left">
                        <ProfileInfo />
                        <ActiveSessions />
                    </div>

                    <div className="grid-right">
                        <SecuritySettings />
                        <PlanCard />
                    </div>
                </div>
            </div>
        </main>
    );
};