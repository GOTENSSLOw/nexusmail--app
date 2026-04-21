import './login.css'; 
import { LoginHero } from './LoginHero';
import { LoginForm } from './LoginForm';

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