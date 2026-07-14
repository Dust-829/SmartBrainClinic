import axios from 'axios'

import { ADMIN_SESSION_STORAGE_KEY } from '@/stores/adminSession'

export const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000').replace(/\/+$/, '')

export interface ApiEnvelope<T> {
  code: number
  message: string
  data: T
}

export const http = axios.create({
  baseURL: apiBaseUrl,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
})

http.interceptors.request.use((config) => {
  if (typeof window === 'undefined') return config

  try {
    const raw = window.sessionStorage.getItem(ADMIN_SESSION_STORAGE_KEY)
    const accessToken = raw ? (JSON.parse(raw) as { accessToken?: unknown }).accessToken : null
    if (typeof accessToken === 'string' && accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`
    }
  } catch {
    // A malformed persisted session must not prevent ordinary API requests.
  }
  return config
})

http.interceptors.response.use(
  (response) => response,
  (error) => {
    const requestUrl = String(error?.config?.url || '')
    const isAdminRequest = requestUrl.includes('/api/v1/auth/admin') || requestUrl.includes('/api/v1/auth/employee') || requestUrl.includes('/api/v1/patient/admin')
    if (typeof window !== 'undefined' && error?.response?.status === 401 && isAdminRequest) {
      window.sessionStorage.removeItem(ADMIN_SESSION_STORAGE_KEY)
      if (!window.location.pathname.startsWith('/admin/login')) {
        window.location.assign(`/admin/login?reason=expired&redirect=${encodeURIComponent(window.location.pathname)}`)
      }
    }
    return Promise.reject(error)
  },
)
