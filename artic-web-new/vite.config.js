import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// The API client calls /api/... relative to the page origin. In dev, Vite
// proxies those to the live Django backend so no CORS setup is needed. In
// production the site is served from articsentinel.com, whose nginx already
// routes /api/ to the backend.
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'https://api.articsentinel.com',
        changeOrigin: true,
      },
    },
  },
})
