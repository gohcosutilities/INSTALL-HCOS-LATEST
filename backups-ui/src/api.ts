import axios from 'axios'

// The domain is embedded in the page URL: /websites/<domain>/backups
const pathParts = window.location.pathname.split('/')
const domainIdx = pathParts.indexOf('websites')
export const currentDomain = domainIdx >= 0 ? pathParts[domainIdx + 1] : ''

// Read server ID from the meta tag injected by the Django template
const metaServer = document.querySelector('meta[name="backup-server-id"]')
export const serverId = metaServer ? metaServer.getAttribute('content') || '' : ''

// Read the initial Keycloak token from the meta tag (may be expired)
const metaKc = document.querySelector('meta[name="backup-kc-token"]')
let kcToken = metaKc ? metaKc.getAttribute('content') || '' : ''

// CSRF token (Django)
function getCsrfToken(): string {
  const cookie = document.cookie.split(';').find(c => c.trim().startsWith('csrftoken='))
  return cookie ? cookie.split('=')[1] : ''
}

// ---------------------------------------------------------------------------
// Token refresh: call CyberPanel's /websites/<domain>/backups/api/refresh-token
// to get a fresh Keycloak access_token using the session's refresh_token.
// ---------------------------------------------------------------------------
const refreshUrl = `/websites/${currentDomain}/backups/api/refresh-token`

let refreshPromise: Promise<string> | null = null

async function refreshAccessToken(): Promise<string> {
  // Deduplicate concurrent refresh requests
  if (refreshPromise) return refreshPromise
  refreshPromise = (async () => {
    try {
      const resp = await axios.post(refreshUrl, null, {
        headers: { 'X-CSRFToken': getCsrfToken() },
      })
      kcToken = resp.data.access_token || ''
      return kcToken
    } catch {
      kcToken = ''
      return ''
    } finally {
      refreshPromise = null
    }
  })()
  return refreshPromise
}

// Eagerly refresh the token on page load so every subsequent request has a
// valid token. This resolves the "expired meta tag token" problem.
const tokenReady: Promise<void> = refreshAccessToken().then(() => {})

// ---------------------------------------------------------------------------
// Axios instance targeting the HCOS backend API (via nginx reverse proxy)
// ---------------------------------------------------------------------------
const defaultHeaders: Record<string, string> = { 'X-CSRFToken': getCsrfToken() }

const api = axios.create({
  baseURL: `https://${window.location.hostname}/api/admin/backups/`,
  headers: defaultHeaders,
})

// Request interceptor: wait for initial refresh, attach Bearer token
api.interceptors.request.use(async (config) => {
  await tokenReady
  if (kcToken) {
    config.headers = config.headers || {}
    config.headers['Authorization'] = `Bearer ${kcToken}`
  }
  return config
})

// Response interceptor: on 401/403, refresh token and retry ONCE
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config
    if (
      error.response &&
      (error.response.status === 401 || error.response.status === 403) &&
      !originalRequest._retried
    ) {
      originalRequest._retried = true
      const newToken = await refreshAccessToken()
      if (newToken) {
        originalRequest.headers['Authorization'] = `Bearer ${newToken}`
        return api.request(originalRequest)
      }
    }
    return Promise.reject(error)
  }
)

// ── Backup Jobs ──────────────────────────────────────────

export interface BackupJob {
  id: number
  server: number
  server_name: string
  domain: string
  backup_type: string
  backup_type_display: string
  status: string
  status_display: string
  storage_backend: string
  storage_backend_display: string
  selected_paths: string[]
  selected_databases: string[]
  remote_path: string
  size_bytes: number | null
  error_message: string
  created_at: string
  started_at: string | null
  completed_at: string | null
}

export function listBackupJobs(params?: Record<string, string>) {
  return api.get<BackupJob[]>('jobs/', { params })
}

export function createBackupJob(data: {
  server: number
  domain: string
  backup_type: string
  storage_backend?: string
  selected_paths?: string[]
  selected_databases?: string[]
}) {
  return api.post<BackupJob>('jobs/', data)
}

export function cancelBackupJob(id: number) {
  return api.post(`jobs/${id}/cancel/`)
}

export function retryBackupJob(id: number) {
  return api.post(`jobs/${id}/retry/`)
}

// ── Restore Jobs ─────────────────────────────────────────

export interface RestoreJob {
  id: number
  backup: number
  server: number
  domain: string
  status: string
  status_display: string
  error_message: string
  created_at: string
  started_at: string | null
  completed_at: string | null
}

export function listRestoreJobs(params?: Record<string, string>) {
  return api.get<RestoreJob[]>('restores/', { params })
}

export function createRestoreJob(data: { backup: number; server: number; domain: string }) {
  return api.post<RestoreJob>('restores/', data)
}

// ── Schedules ────────────────────────────────────────────

export interface BackupSchedule {
  id: number
  server: number
  domain: string
  backup_type: string
  storage_backend: string
  frequency: string
  retention_count: number
  is_active: boolean
  last_run: string | null
  next_run: string | null
}

export function listSchedules(params?: Record<string, string>) {
  return api.get<BackupSchedule[]>('schedules/', { params })
}

export function createSchedule(data: Partial<BackupSchedule>) {
  return api.post<BackupSchedule>('schedules/', data)
}

export function updateSchedule(id: number, data: Partial<BackupSchedule>) {
  return api.patch<BackupSchedule>(`schedules/${id}/`, data)
}

export function deleteSchedule(id: number) {
  return api.delete(`schedules/${id}/`)
}

// ── Server-side helpers ──────────────────────────────────

export function listRemoteBackups(sId: string | number, domain: string) {
  return api.get(`../servers/${sId}/domains/${domain}/remote-backups/`)
}

export function listDomainDatabases(sId: string | number, domain: string) {
  return api.get(`../servers/${sId}/domains/${domain}/databases/`)
}

export function listDomainFiles(sId: string | number, domain: string, path = '') {
  return api.get(`../servers/${sId}/domains/${domain}/files/`, { params: { path } })
}

export function deployAgent(sId: string | number) {
  return api.post(`../servers/${sId}/deploy-agent/`)
}
