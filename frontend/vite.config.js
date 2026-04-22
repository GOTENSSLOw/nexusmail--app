import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// VITE_BACKEND_HOST: set by start-vm.sh to the VM's real IP so that
// proxy traffic traverses the network interface (capturable by Wireshark).
// Falls back to 127.0.0.1 for local development.
const backendHost = process.env.VITE_BACKEND_HOST || '127.0.0.1'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': {
        target: `http://${backendHost}:8000`,
        changeOrigin: true,
      },
    },
  },
})
