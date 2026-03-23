import './Login.css'; 
import Logo from '../assets/Logo.png';
import {Route, useNavigate, useNavigation} from 'react-router-dom'


export const Login = () => {
    const navigate = useNavigate();
    const handleLogin = (e) => {
        e.preventDefault();
        navigate('/inbox');
    };
    return (
        <div className="login-container">
            <div className="login-card">
                
                <div className="login-header">
                    <img src={Logo} alt="NexusMail Logo" />
                    <h1>NexusMail</h1>
                </div>
                
                <div className="login-hero">
                    <h2>Bienvenido</h2>
                    <p>Ingresa tus datos </p>
                </div>
                
                <form className="login-form" onSubmit={handleLogin}>
                    
                    <div className="input-group">
                        <label>Nickname</label>
                        <input type="text" placeholder="Ingresa tu nickname" required />
                    </div>

                    <div className="input-group">
                        <div className="password-labels">
                            <label>Contraseña</label>
                            <a href="#" className="forgot-link">¿Olvidaste tu contraseña?</a>
                        </div>
                        <input type="password" placeholder="••••••••" required />
                    </div>

                    <div className="checkbox-group">
                        <input type="checkbox" id="keep-signed" />
                        <label htmlFor="keep-signed">¿Mantener sesión iniciada? </label>
                    </div>

                    <button type="submit" className="btn-primary">
                        Ingresar→
                    </button>
                </form>
            </div>
        </div>
    )
}