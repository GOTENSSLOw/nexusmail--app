import Logo from '../../assets/Logo.png';

export const LoginHero = () => {
    return (
        <>
            <div className="login-header">
                <img src={Logo} alt="NexusMail Logo" />
                <h1>NexusMail</h1>
            </div>
            <div className="login-hero">
                <h2>Bienvenido</h2>
                <p>Ingresa tus datos</p>
            </div>
        </>
    );
};