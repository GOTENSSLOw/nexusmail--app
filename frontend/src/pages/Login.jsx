import './Login.css'; 
import { LoginHero } from './Login/LoginHero';
import { LoginForm } from './Login/LoginForm';

export const Login = () => {
    return (
        <div className="background-login">
            <div className="login-container">
                <div className="login-card">
                    <LoginHero />
                    <LoginForm />
                </div>
            </div>
        </div>
    );
};