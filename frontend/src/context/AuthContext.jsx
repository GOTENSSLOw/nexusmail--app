import { createContext, useContext, useState } from 'react';

const AUTH_STORAGE_KEY = 'nexusmail_auth';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const stored = localStorage.getItem(AUTH_STORAGE_KEY);
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  }); // { username, password }

  const login = (username, password) => {
    const credentials = { username, password };
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(credentials));
    setUser(credentials);
  };

  const logout = () => {
    localStorage.removeItem(AUTH_STORAGE_KEY);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{
      username: user?.username,
      password: user?.password,
      isAuthenticated: !!user,
      login,
      logout,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
