import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { LoginInput } from './LoginInput';
import { useAuth } from '../../context/AuthContext';
import { loginUser } from '../../services/api';

export const LoginForm = () => {
    const navigate = useNavigate();
    const { login } = useAuth();
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            await loginUser(username, password);
            login(username, password);
            navigate('/inbox');
        } catch (err) {
            setError(err.message || 'Credenciales inválidas');
        } finally {
            setLoading(false);
        }
    };

    return (
        <form className="login-form" onSubmit={handleLogin}>
            {error && <div style={{ color: 'red', marginBottom: '10px' }}>{error}</div>}
            <LoginInput
                label="Nickname"
                tipo="text"
                placeholder="Ingresa tu nickname"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                name="username"
            />

            <LoginInput
                label="Contraseña"
                tipo="password"
                placeholder="••••••••"
                olvidarContra={true}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                name="password"
            />

            <div className="checkbox-group">
                <input type="checkbox" id="keep-signed" />
                <label htmlFor="keep-signed">¿Mantener sesión iniciada?</label>
            </div>

            <button type="submit" className="btn-primary" disabled={loading}>
                {loading ? 'Ingresando...' : 'Ingresar →'}
            </button>
        </form>
    );
};