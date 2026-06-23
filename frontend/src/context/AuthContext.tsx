/**
 * Global auth state.
 *
 * Holds current user + login/register/logout actions.
 * On mount, if a token exists, fetches /users/me/ to restore session.
 */

import { createContext, useCallback, useEffect, useState, type ReactNode } from 'react';
import { authApi } from '../api/auth';
import { setAuthFailureHandler } from '../api/client';
import { tokenStore } from '../utils/token';
import type { LoginCredentials, RegisterCredentials, User } from '../types';

interface AuthContextValue {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (creds: LoginCredentials) => Promise<void>;
  register: (creds: RegisterCredentials) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

// eslint-disable-next-line react-refresh/only-export-components
export const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const logout = useCallback(() => {
    tokenStore.clear();
    setUser(null);
  }, []);

  // Let the axios refresh-failure handler force a logout.
  useEffect(() => {
    setAuthFailureHandler(logout);
  }, [logout]);

  // Restore session on load.
  useEffect(() => {
    const restore = async () => {
      if (!tokenStore.getAccess()) {
        setIsLoading(false);
        return;
      }
      try {
        const me = await authApi.getMe();
        setUser(me);
      } catch {
        tokenStore.clear();
      } finally {
        setIsLoading(false);
      }
    };
    restore();
  }, []);

  const login = useCallback(async (creds: LoginCredentials) => {
    const tokens = await authApi.login(creds);
    tokenStore.set(tokens.access, tokens.refresh);
    const me = await authApi.getMe();
    setUser(me);
  }, []);

  const register = useCallback(
    async (creds: RegisterCredentials) => {
      await authApi.register(creds);
      // Auto-login after register (backend returns no token).
      await login({ username: creds.username, password: creds.password });
    },
    [login],
  );

  // Re-fetch the current user after profile edits so the navbar/header
  // reflect changes immediately without a full page reload.
  const refreshUser = useCallback(async () => {
    const me = await authApi.getMe();
    setUser(me);
  }, []);

  const value: AuthContextValue = {
    user,
    isLoading,
    isAuthenticated: user !== null,
    login,
    register,
    logout,
    refreshUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
