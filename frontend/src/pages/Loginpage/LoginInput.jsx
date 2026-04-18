export const LoginInput = ({ label, tipo, placeholder, olvidarContra, value, onChange, name }) => {
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

            <input type={tipo} placeholder={placeholder} required value={value} onChange={onChange} name={name} />
        </div>
    );
};