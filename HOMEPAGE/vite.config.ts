import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { fileURLToPath, URL } from 'node:url'
import mkcert from 'vite-plugin-mkcert'
import dotenv from 'dotenv'
import vueJsx from '@vitejs/plugin-vue-jsx'
dotenv.config({ path: './.env' })
// https://vite.dev/config/
export default defineConfig({


  plugins: [
    vue(),
    tailwindcss(),
     mkcert({
      hosts: ['localhost'],
    }),
    vueJsx()
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
})

