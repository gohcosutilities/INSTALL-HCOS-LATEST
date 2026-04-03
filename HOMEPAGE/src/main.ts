import { createApp } from 'vue'
import { initKeycloak } from './services/auth.ts'
import './style.css'
import App from './App.vue'
import { createPinia } from 'pinia'
import { useLoadingStore } from './store/loading'
import router from './router'
import Aura from '@primeuix/themes/aura';
import PrimeVue from 'primevue/config';
import 'primeicons/primeicons.css'
import Dialog from 'primevue/dialog';
import { fetchBranding } from './services/branding'

async function bootstrap() {
  // Silent SSO check (no forced login)
  await initKeycloak({ loginRequired: false })

  // Pre-fetch branding configuration (non-blocking)
  fetchBranding().catch(e => console.warn('[Branding] Initial fetch failed:', e))

  const app = createApp(App)
  const pinia = createPinia()

  app.use(pinia)
  app.use(PrimeVue, {
    theme: {
        preset: Aura
    }
});
  

  // Setup global loader via router guards
  const loadingStore = useLoadingStore()
  router.beforeEach((_to, _from, next) => {
    loadingStore.show()
    next()
  })
  router.afterEach(() => {
    // Give next tick for component mount/paint
    requestAnimationFrame(() => loadingStore.hide())
  })

  app.use(router)
  app.component('Dialog', Dialog);




  // Show loader during initial keycloak + first paint
  const loadingStoreInitial = useLoadingStore()
  loadingStoreInitial.show()
  app.mount('#app')
  requestAnimationFrame(() => loadingStoreInitial.hide())
}

bootstrap().catch(() => {
  // Silent failure handling already done in initKeycloak
})
