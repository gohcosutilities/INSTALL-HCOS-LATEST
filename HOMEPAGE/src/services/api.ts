import axios, { AxiosRequestConfig, AxiosResponse } from 'axios'
import {
  auth,
  ensureFreshToken,
  getToken,
  handleLogin
} from '@/services/auth.ts'

const instance = axios.create({
  baseURL: import.meta.env.VITE_BACKEND_URI,
  withCredentials: true
})

// Helper function to get CSRF token from cookie
function getCsrfToken(): string | null {
  const name = 'csrftoken'
  const value = `; ${document.cookie}`
  const parts = value.split(`; ${name}=`)
  if (parts.length === 2) {
    return parts.pop()?.split(';').shift() || null
  }
  return null
}

// Helper function to ensure CSRF cookie exists
let csrfFetchPromise: Promise<void> | null = null
async function ensureCsrfToken(): Promise<void> {
  // If token already exists, no need to fetch
  if (getCsrfToken()) {
    return
  }

  // If already fetching, wait for that request
  if (csrfFetchPromise) {
    return csrfFetchPromise
  }

  // Fetch CSRF token from backend
  csrfFetchPromise = instance.get('/csrf-token/')
    .catch((err) => {
      // If the endpoint doesn't exist, try the common Django endpoint
      return instance.get('/api/csrf/')
    })
    .catch((err) => {
      // If neither works, just log and continue - the backend might set it on first POST
      console.warn('Could not pre-fetch CSRF token:', err)
    })
    .finally(() => {
      csrfFetchPromise = null
    })

  return csrfFetchPromise
}

// Single request interceptor
instance.interceptors.request.use(async (config) => {
  // Ensure CSRF token exists for non-GET requests
  if (config.method && !['get', 'head', 'options'].includes(config.method.toLowerCase())) {
    await ensureCsrfToken()
  }

  // Only try refresh if already authenticated (non-blocking for anonymous)
  if (auth.isAuthenticated) {
    try {
      await ensureFreshToken(5)
    } catch (e) {
      // Silent here; a 401 later will surface
      console.warn('Failed to refresh before request', e)
    }
  }

  // Add auth header using proper AxiosHeaders methods (Axios 1.x compatibility)
  const token = getToken()
  if (token) {
    config.headers.set('Authorization', `Bearer ${token}`)
  }

  // Add CSRF token for non-GET requests
  if (config.method && !['get', 'head', 'options'].includes(config.method.toLowerCase())) {
    const csrfToken = getCsrfToken()
    if (csrfToken) {
      config.headers.set('X-CSRFToken', csrfToken)
    }
  }

  // FormData handling - let browser set Content-Type with boundary
  if (config.data instanceof FormData) {
    config.headers.delete('Content-Type')
  } else if (!config.headers.get('Content-Type')) {
    config.headers.set('Content-Type', 'application/json')
  }
  return config
})

// Response interceptor for 401 retry once
instance.interceptors.response.use(
  (resp) => resp,
  async (error) => {
    const original = error.config
    if (error.response?.status === 401 && !original?._retry) {
      original._retry = true
      if (auth.isAuthenticated) {
        try {
          await ensureFreshToken(5)
          // Use proper header method for retry
          const token = getToken()
          if (token) {
            original.headers.set('Authorization', `Bearer ${token}`)
          }
          return instance(original)
        } catch (e) {
          console.error('Token refresh on 401 failed', e)
        }
      }
    }
    return Promise.reject(error)
  }
)

// Generic request wrapper
interface RequestOptions {
  requireAuth?: boolean // if true and not logged in => trigger login
  autoLogin?: boolean   // if true attempt login flow automatically
  params?: Record<string, unknown>
  headers?: Record<string, string>
  responseType?: AxiosRequestConfig['responseType']
}

async function prepareAuth (opts?: RequestOptions) {
  if (opts?.requireAuth) {
    if (!auth.isAuthenticated) {
      if (opts.autoLogin) {
        await handleLogin()
      } else {
        throw new Error('Authentication required')
      }
    }
    await ensureFreshToken(30)
  }
}

async function request<T = unknown>(
  method: string,
  url: string,
  data?: unknown,
  opts: RequestOptions = {}
): Promise<T> {
  await prepareAuth(opts)
  const resp: AxiosResponse<T> = await instance.request({
    method,
    url,
    data,
    params: opts.params,
    headers: opts.headers,
    responseType: opts.responseType
  })
  return resp.data
}

// Public by default (set requireAuth: true to force login)
export const get = <T = unknown>(url: string, opts?: RequestOptions) =>
  request<T>('GET', url, undefined, opts)

export const del = <T = unknown>(url: string, opts?: RequestOptions) =>
  request<T>('DELETE', url, undefined, opts)

export const post = <B = unknown, R = unknown>(
  url: string,
  body?: B,
  opts?: RequestOptions & { multipart?: boolean }
) => {
  const headers = { ...(opts?.headers || {}) }
  if (opts?.multipart) {
    // Let browser set boundary
    delete headers['Content-Type']
  }
  return request<R>('POST', url, body, { ...opts, headers })
}

export const put = <B = unknown, R = unknown>(
  url: string,
  body?: B,
  opts?: RequestOptions
) => request<R>('PUT', url, body, opts)

export const patch = <B = unknown, R = unknown>(
  url: string,
  body?: B,
  opts?: RequestOptions
) => request<R>('PATCH', url, body, opts)

export async function uploadFiles<R = unknown>(
  url: string,
  files: File[],
  fieldName = 'files',
  opts?: RequestOptions
) {
  const form = new FormData()
  files.forEach(f => form.append(fieldName, f))
  return post<FormData, R>(url, form, { ...opts, multipart: true })
}

export async function uploadFile<R = unknown>(
  url: string,
  file: File,
  fieldName = 'file',
  opts?: RequestOptions
) {
  const form = new FormData()
  form.append(fieldName, file)
  return post<FormData, R>(url, form, { ...opts, multipart: true })
}

export async function downloadFile(
  url: string,
  filename = 'file',
  opts?: RequestOptions
) {
  const data = await request<Blob>('GET', url, undefined, {
    ...opts,
    responseType: 'blob'
  })
  const blob = new Blob([data])
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(link.href)
}

// WebSocket helper (token optional for anonymous users)
export function createWebSocket(conversationId: string): Promise<WebSocket> {
  return new Promise((resolve, reject) => {
    try {
      const token = getToken()
      
      // Use VITE_WS_URI or construct from VITE_BACKEND_URI
      const wsBaseUrl = import.meta.env.VITE_WS_URI || 
        (import.meta.env.VITE_BACKEND_URI?.replace(/^https?:/, 'wss:').replace(/^http:/, 'ws:'))
      
      // Remove trailing slash from base URL and conversation ID
      const cleanBaseUrl = wsBaseUrl?.replace(/\/$/, '') || 'wss://request.hcos.io'
      const cleanConvId = conversationId.replace(/^\//, '')
      
      // Construct WebSocket URL
      let wsUrl = `${cleanBaseUrl}/ws/chat/${cleanConvId}/`
      
      // Add token if available (authenticated users)
      if (token) {
        wsUrl += `?token=${encodeURIComponent(token)}`
      }
      
      console.log('Creating WebSocket connection to:', wsUrl.replace(/token=[^&]+/, 'token=***'))
      
      const ws = new WebSocket(wsUrl)
      
      // Set up connection timeout
      const connectionTimeout = setTimeout(() => {
        if (ws.readyState !== WebSocket.OPEN) {
          ws.close()
          reject(new Error('WebSocket connection timeout'))
        }
      }, 30000) // 30 second timeout
      
      ws.onopen = () => {
        clearTimeout(connectionTimeout)
        console.log('WebSocket connection established')
        resolve(ws)
      }
      
      ws.onerror = (error) => {
        clearTimeout(connectionTimeout)
        console.error('WebSocket connection error:', error)
        reject(new Error('WebSocket connection failed'))
      }
      
    } catch (error) {
      console.error('Error creating WebSocket:', error)
      reject(error)
    }
  })
}

export default instance
