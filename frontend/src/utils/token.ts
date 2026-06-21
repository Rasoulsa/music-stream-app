/**
 * Token storage helpers (localStorage).
 *
 * NOTE: localStorage is vulnerable to XSS. For this demo it is an
 * acceptable tradeoff. Production hardening = httpOnly refresh cookie.
 */

const ACCESS_KEY = 'access_token';
const REFRESH_KEY = 'refresh_token';

export const tokenStore = {
  getAccess: (): string | null => localStorage.getItem(ACCESS_KEY),
  getRefresh: (): string | null => localStorage.getItem(REFRESH_KEY),

  set: (access: string, refresh: string): void => {
    localStorage.setItem(ACCESS_KEY, access);
    localStorage.setItem(REFRESH_KEY, refresh);
  },

  setAccess: (access: string): void => {
    localStorage.setItem(ACCESS_KEY, access);
  },

  clear: (): void => {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
  },
};
