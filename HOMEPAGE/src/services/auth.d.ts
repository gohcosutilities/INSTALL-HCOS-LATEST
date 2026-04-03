export interface AuthState { isAuthenticated: boolean; userProfile: any; token: string | null; keycloak: any; isInitialized: boolean }
export const auth: AuthState
export function initKeycloak(options?: { onAuthenticated?: () => void; loginRequired?: boolean }): Promise<boolean>
export function handleLogin(options?: any): Promise<void>
export function handleRegister(): Promise<void>
export function handleLogout(): Promise<void>
export function ensureAuthenticated(redirectTo?: string | null): Promise<boolean>
export function getToken(): string | null
