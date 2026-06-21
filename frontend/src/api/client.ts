/**
 * Axios client with JWT auth.
 *
 * - Request interceptor: attaches Bearer access token.
 * - Response interceptor: on 401, tries one refresh, then retries.
 *   If refresh fails → clears tokens and lets the error propagate.
 */

import axios, {
  AxiosError,
  type AxiosRequestConfig,
  type InternalAxiosRequestConfig,
} from 'axios';
import { tokenStore } from '../utils/token';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000/api/v1';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// ── Request: attach access token ──────────────────────
apiClient.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const access = tokenStore.getAccess();
  if (access) {
    config.headers.Authorization = `Bearer ${access}`;
  }
  return config;
});

// ── Response: refresh on 401 ──────────────────────────
interface RetryConfig extends AxiosRequestConfig {
  _retry?: boolean;
}

// Called by AuthContext to react to forced logout.
let onAuthFailure: (() => void) | null = null;
export const setAuthFailureHandler = (fn: () => void) => {
  onAuthFailure = fn;
};

apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const original = error.config as RetryConfig;

    const isAuthEndpoint =
      original?.url?.includes('/auth/login') ||
      original?.url?.includes('/auth/refresh');

    if (
      error.response?.status === 401 &&
      original &&
      !original._retry &&
      !isAuthEndpoint
    ) {
      original._retry = true;
      const refresh = tokenStore.getRefresh();

      if (refresh) {
        try {
          const { data } = await axios.post<{ access: string }>(
            `${BASE_URL}/auth/refresh/`,
            { refresh },
          );
          tokenStore.setAccess(data.access);
          original.headers = original.headers ?? {};
          original.headers.Authorization = `Bearer ${data.access}`;
          return apiClient(original);
        } catch {
          tokenStore.clear();
          onAuthFailure?.();
        }
      } else {
        tokenStore.clear();
        onAuthFailure?.();
      }
    }

    return Promise.reject(error);
  },
);
