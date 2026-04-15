import { useNavigate } from 'react-router-dom';
import { LoginInput } from './LoginInput';

export const LoginForm = () => {
    const navigate = useNavigate();
    
    const handleLogin = (e) => {
        e.preventDefault();
        navigate('/inbox');
    };

    return (
        <form className="login-form" onSubmit={handleLogin}>
            
            <LoginInput 
                label="Nickname" 
                tipo="text" 
                placeholder="Ingresa tu nickname" 
            />

            <LoginInput 
                label="Contraseña" 
                tipo="password" 
                placeholder="••••••••" 
                olvidarContra={true} 
            />

            <div className="checkbox-group">
                <input type="checkbox" id="keep-signed" />
                <label htmlFor="keep-signed">¿Mantener sesión iniciada?</label>
            </div>

            <button type="submit" className="btn-primary">
                Ingresar →
            </button>
        </form>
    );
};