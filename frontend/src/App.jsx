import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom'
import { Login } from './pages/Loginpage/Login'
import { Dashboard } from './pages/Dashboardpage/Dashboard'
import { AccountSettings } from './pages/AccountSettingspage/accountsettings'
import { Layout } from './pages/Layout' 
import { Sent } from './pages/sent'

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="/login" element={<Login />} />
  
        <Route element={<Layout />}>
          <Route path="/inbox" element={<Dashboard />} />
          <Route path="/settings" element={<AccountSettings />} />
          <Route path="/sent" element={<Sent />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
export default App