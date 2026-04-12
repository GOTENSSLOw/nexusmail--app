import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import { ProtectedRoute } from './components/ProtectedRoute'
import { Login } from './pages/Login'
import { Dashboard } from './pages/Dashboard'
import { AccountSettings } from './pages/accountsettings'
import { Layout } from './pages/Layout'
import { Sent } from './pages/sent'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route path="/login" element={<Login />} />

          <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
            <Route path="/inbox" element={<Dashboard />} />
            <Route path="/settings" element={<AccountSettings />} />
            <Route path="/sent" element={<Sent />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
export default App