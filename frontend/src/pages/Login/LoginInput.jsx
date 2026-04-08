export const LoginInput = ({ label, tipo, placeholder, olvidarContra }) => {
    return (
        <div className="input-group">
            {olvidarContra ? (
                <div className="password-labels">
                    <label>{label}</label>
                    <a href="#" className="forgot-link">¿Olvidaste tu contraseña?</a>
                </div>
            ) : (
                <label>{label}</label>
            )}
            
            <input type={tipo} placeholder={placeholder} required />
        </div>
    );
};