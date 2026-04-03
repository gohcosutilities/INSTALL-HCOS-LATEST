import { reactive } from 'vue'
// @ts-ignore - keycloak-js types may need install
import Keycloak from 'keycloak-js'
import router from '@/router'

interface KeycloakProfile { [k: string]: any }
interface InitOptions { onAuthenticated?: () => void; loginRequired?: boolean }

const keycloakConfig = {
  url: import.meta.env.VITE_AUTHENTICATION_URL,
  realm: 'master',
  clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || 'hcos-frontend'
}

let keycloak: any = new Keycloak(keycloakConfig)
let refreshTimer: any = null
let updatingToken: Promise<any> | null = null

export const auth = reactive({
  isAuthenticated: false,
  userProfile: null as KeycloakProfile | null,
  token: null as string | null,
  keycloak,
  isInitialized: false
})

export const initKeycloak = (optionsOrCallback: InitOptions | (() => void) = {}): Promise<boolean> => {
  console.log('initKeycloak called', { isInitialized: auth.isInitialized })
  
  // Prevent multiple initializations
  if (auth.isInitialized) {
    console.warn('Keycloak already initialized, skipping re-initialization')
    return Promise.resolve(auth.isAuthenticated)
  }

  let onAuthenticatedCallback: (() => void) | null = null
  let loginRequired = false
  if (typeof optionsOrCallback === 'function') {
    onAuthenticatedCallback = optionsOrCallback
  } else if (optionsOrCallback && typeof optionsOrCallback === 'object') {
    const opt = optionsOrCallback as InitOptions
    onAuthenticatedCallback = opt.onAuthenticated ?? null
    loginRequired = opt.loginRequired ?? false
  }
  const urlParams = new URLSearchParams(window.location.search)
  const hasLoginError = urlParams.get('error') === 'login_required'
  const comingFromRegister = !!localStorage.getItem('pending-registration')
  const onLoadMode = loginRequired ? 'login-required' : 'check-sso'
  let forceLoginAfterInit = false
  if (hasLoginError || (comingFromRegister && !loginRequired)) {
    forceLoginAfterInit = true
  }
  return (keycloak as any).init({
    onLoad: onLoadMode,
    pkceMethod: 'S256',
    flow: 'standard',
    checkLoginIframe: false,
    enableLogging: true,
    useLocalStorage: true
  }).then(async (authenticated: boolean) => {
    // Always mark as initialized, regardless of authentication status
    auth.isInitialized = true
    
    if (authenticated) {
      auth.isAuthenticated = true
      auth.token = (keycloak as any).token
      localStorage.setItem('kc-token', auth.token || '')
      try {
        const profile = await (keycloak as any).loadUserProfile()
        auth.userProfile = profile as any
      } catch {
        auth.userProfile = null
      }
      startRefreshLoop()
      if (comingFromRegister) localStorage.removeItem('pending-registration')
      const redirectPath = localStorage.getItem('post-auth-redirect')
      if (redirectPath) {
        localStorage.removeItem('post-auth-redirect')
        const current = window.location.pathname + window.location.search
        if (redirectPath !== current) {
          try { router.replace(redirectPath) } catch {/* ignore */}
        }
      }
      if (onAuthenticatedCallback) onAuthenticatedCallback()
      return true
    }
    
    // User is not authenticated, but Keycloak is still initialized
    if (forceLoginAfterInit) {
      await handleLogin()
    } else if (loginRequired) {
      await handleLogin()
    } else {
      console.warn('Not authenticated (passive check).')
    }
    return false
  }).catch((error: any) => {
    console.error('Authentication init failed', error)
    throw error
  })
}

function startRefreshLoop() {
  if (refreshTimer) return
  refreshTimer = setInterval(async () => {
    if (!auth.isAuthenticated) return
    try { await updateToken(60) } catch (e) { console.error('Background token refresh failed', e) }
  }, 30000)
}

export async function updateToken(minValidity = 60) {
  if (!auth.isAuthenticated) return null
  if (updatingToken) return updatingToken
  updatingToken = (keycloak as any).updateToken(minValidity)
    .then((refreshed: boolean) => {
      if (refreshed) {
        auth.token = (keycloak as any).token
        if (auth.token) localStorage.setItem('kc-token', auth.token)
      }
      return auth.token
    })
  .catch((err: unknown) => { console.error('updateToken failed', err); throw err })
    .finally(() => { updatingToken = null })
  return updatingToken
}

export async function ensureFreshToken(minValidity = 30) {
  if (!auth.isAuthenticated) return null
  return updateToken(minValidity)
}

export function getAuthHeader() {
  const token = getToken()
  return token ? { Authorization: `Bearer ${token}` } : {}
}

export async function handleLogin(options: any = {}) {
  const redirectPath = window.location.pathname + window.location.search
  localStorage.setItem('post-auth-redirect', redirectPath)
  await (keycloak as any).login(options)
}

export async function handleRegister() {
  console.log('handleRegister called', { 
    keycloakExists: !!keycloak, 
    isInitialized: auth.isInitialized,
    isAuthenticated: auth.isAuthenticated 
  })
  
  if (!keycloak) {
    throw new Error('Keycloak instance not initialized')
  }
  
  // Don't re-initialize Keycloak! It can only be initialized once.
  // If it's not initialized, there's a bigger problem with app startup.
  if (!auth.isInitialized) {
    throw new Error('Keycloak should have been initialized during app startup. Check main.ts initialization.')
  }
  
  // For newer Keycloak versions, register method might need options or behave differently
  try {
    if (typeof keycloak.register === 'function') {
      console.log('Using keycloak.register() method')
      await (keycloak as any).register({
        redirectUri: window.location.origin
      })
    } else {
      console.log('Using fallback registration URL method')
      // Fallback: construct registration URL manually
      const config = keycloakConfig
      const registrationUrl = `${config.url}/realms/${config.realm}/protocol/openid-connect/registrations?client_id=${config.clientId}&response_type=code&redirect_uri=${encodeURIComponent(window.location.origin)}`
      localStorage.setItem('pending-registration', 'true')
      window.location.href = registrationUrl
    }
  } catch (error) {
    console.error('Registration failed, trying fallback method:', error)
    // Fallback: construct registration URL manually
    const config = keycloakConfig
    const registrationUrl = `${config.url}/realms/${config.realm}/protocol/openid-connect/registrations?client_id=${config.clientId}&response_type=code&redirect_uri=${encodeURIComponent(window.location.origin)}`
    localStorage.setItem('pending-registration', 'true')
    window.location.href = registrationUrl
  }
}

export async function handleLogout() {
  try { await (keycloak as any).logout({ redirectUri: window.location.origin }) } finally { clearAuthState() }
}

function clearAuthState() {
  auth.isAuthenticated = false
  auth.userProfile = null
  auth.token = null
  localStorage.removeItem('kc-token')
}

export async function ensureAuthenticated(redirectTo: string | null = null) {
  if (auth.isAuthenticated) return true
  
  // Don't re-initialize! Keycloak should already be initialized during app startup
  if (!auth.isInitialized) {
    console.error('Keycloak not initialized. This should not happen after app startup.')
    // Instead of re-initializing, just proceed to login
  }
  
  if (!auth.isAuthenticated) {
    if (redirectTo) localStorage.setItem('post-auth-redirect', redirectTo)
    else localStorage.setItem('post-auth-redirect', window.location.pathname + window.location.search)
    await handleLogin()
    return false
  }
  return true
}

export async function getFreshToken() {
  if (!auth.isAuthenticated) throw new Error('User not authenticated. Call ensureAuthenticated() first.')
  return ensureFreshToken(30)
}

export const getToken = () => auth.token || (keycloak as any).token || localStorage.getItem('kc-token')
export const getUsername = () => (keycloak as any).tokenParsed?.given_name
export const getKeycloak = () => keycloak

export async function withAuthentication(apiCall: () => Promise<any>, options: { redirectOnFail?: boolean; minValidity?: number } = {}) {
  const { redirectOnFail = true, minValidity = 30 } = options
  try {
    if (!auth.isAuthenticated) {
      if (redirectOnFail) {
        await ensureAuthenticated()
        return
      } else {
        throw new Error('Authentication required')
      }
    }
    await ensureFreshToken(minValidity)
    return await apiCall()
  } catch (error: any) {
    if (error.message === 'Authentication required' && redirectOnFail) {
      await ensureAuthenticated()
      return
    }
    return
  }
}
