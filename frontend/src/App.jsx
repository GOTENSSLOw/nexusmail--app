import { BrowserRouter, Route, Routes, Navigate } from 'react-router-dom'
import { Login } from './pages/Login'
import { Dashboard } from './pages/Dashboard'
import { AccountSettings } from './pages/accountsettings'
import { Layout } from './pages/Layout' 

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="/login" element={<Login />} />
        
        {/* El Layout envuelve a las demas rutas*/}
        <Route element={<Layout />}>
          <Route path="/inbox" element={<Dashboard />} />
          <Route path="/settings" element={<AccountSettings />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
export default App