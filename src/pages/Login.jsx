import './Login.css'; 
import Logo from '../assets/Logo.png';

export const Login = () => {
    return (
        <div className="login-container">
            <div className="login-card">
                
                <div className="login-header">
                    <img src={Logo} alt="NexusMail Logo" />
                    <h1>NexusMail</h1>
                </div>
                
                <div className="login-hero">
                    <h2>Bienvenido</h2>
                    <p>Ingresa  tus datos </p>
                </div>
                
                <form className="login-form">
                    
                    <div className="input-group">
                        <label>nickname</label>
                        <input type="text" placeholder="Ingresa tu nickname" />
                    </div>

                    <div className="input-group">
                        <div className="password-labels">
                            <label>contraseña</label>
                            <a href="#" className="forgot-link">olvidaste contraseña?</a>
                        </div>
                        <input type="password" placeholder="••••••••" />
                    </div>

                    <div className="checkbox-group">
                        <input type="checkbox" id="keep-signed" />
                        <label htmlFor="keep-signed">Guardar sesion </label>
                    </div>

                    <button type="button" className="btn-primary">Ingresar→</button>
                </form>
            </div>
        </div>
    )
}