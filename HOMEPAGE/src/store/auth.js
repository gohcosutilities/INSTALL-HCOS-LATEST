import { reactive } from 'vue'
import Keycloak from 'keycloak-js'
import router from '@/router'

// --- Configuration ---
const keycloakConfig = {
  url: import.meta.env.VITE_AUTHENTICATION_URL || 'http://localhost:8080',
  realm: 'master',
  clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || 'hcos-frontend'
}

// --- Internal State ---
let keycloak = new Keycloak(keycloakConfig)
let initPromise = null
let refreshTimer = null
let updatingToken = null // concurrency guard

// --- Reactive Exported Auth State ---
export const auth = reactive({
  isAuthenticated: false,
  userProfile: null,
  token: null,
  keycloak
})

// --- Init ---
/**
 * Initializes Keycloak once. Call (and await) this before mounting the app.
 * @param {Object} options
 * @param {boolean} [options.loginRequired=false] Force login (login-required) instead of silent check (check-sso).
 */
export function initKeycloak (options = {}) {
  if (initPromise) return initPromise

  const { loginRequired = false } = options

  const initOptions = {
    onLoad: 'check-sso',
    pkceMethod: 'S256',
    flow: 'standard',
    checkLoginIframe: false,
    enableLogging: true,
    useLocalStorage: true
  }

  initPromise = keycloak.init(initOptions)
    .then(async (authenticated) => {
      // If not authenticated
      if (!authenticated) {
        if (loginRequired) {
          // Force a login redirect
            await handleLogin()
          return false
        } else {
          // Silent check failed but not required to login
          clearAuthState()
          return false
        }
      }
      // Authenticated path
      await afterAuthSuccess()
      startRefreshLoop()
      return true
    })
    .catch(err => {
      console.error('Keycloak init failed', err)
      clearAuthState()
      throw err
    })

  return initPromise

}



async function afterAuthSuccess () {
  auth.isAuthenticated = true
  auth.token = keycloak.token
  try {
    auth.userProfile = await keycloak.loadUserProfile()
  } catch (e) {
    console.warn('Failed to load user profile', e)
  }
  localStorage.setItem('kc-token', auth.token)
}

function startRefreshLoop () {
  if (refreshTimer) return
  refreshTimer = setInterval(async () => {
    // Passive refresh (do not force login if logged out)
    if (!auth.isAuthenticated) return
    try {
      await updateToken(60)
    } catch (e) {
      console.error('Background token refresh failed', e)
    }
  }, 30000)
}

// --- Token Helpers ---
export async function updateToken (minValidity = 60) {
  if (!auth.isAuthenticated) return null
  if (updatingToken) return updatingToken
  updatingToken = keycloak.updateToken(minValidity)
    .then(refreshed => {
      if (refreshed) {
        auth.token = keycloak.token
        localStorage.setItem('kc-token', auth.token)
      }
      return auth.token
    })
    .catch(err => {
      console.error('updateToken failed', err)
      throw err
    })
    .finally(() => { updatingToken = null })
  return updatingToken
}

export async function ensureFreshToken (minValidity = 30) {
  if (!auth.isAuthenticated) return null
  return updateToken(minValidity)
}

export function getAuthHeader () {
  const token = getToken()
  return token ? { Authorization: `Bearer ${token}` } : {}
}

// --- Auth Actions ---
export async function handleLogin (options = {}) {
  // This just triggers the login redirect.
  // The user will be brought back to the app, and initKeycloak will run again.
  await keycloak.login(options)
}

export async function loginAndRedirect(redirectPath) {
  if (!redirectPath) {
    console.error('loginAndRedirect requires a redirectPath.');
    return;
  }
  // Store the path to redirect to after login
  localStorage.setItem('post-auth-redirect', redirectPath);
  await handleLogin();
}

export async function handleRegister () {
  await keycloak.register()
}

export async function handleLogout () {
  try {
    await keycloak.logout({ redirectUri: window.location.origin })
  } finally {
    clearAuthState()
  }
}

function clearAuthState () {
  auth.isAuthenticated = false
  auth.userProfile = null
  auth.token = null
  localStorage.removeItem('kc-token')
}

// --- Utility ---
export async function ensureAuthenticated () {
  if (!auth.isAuthenticated) {
    await handleLogin()
  }
}

export async function getFreshToken () {
  return ensureFreshToken(30)
}

export const getToken = () => auth.token || keycloak.token || localStorage.getItem('kc-token')
export const getUsername = () => keycloak.tokenParsed?.given_name
export const getKeycloak = () => keycloak