/**
 * Auth API calls.
 */

import { apiClient } from './client';
import type {
  LoginCredentials,
  RegisterCredentials,
  RegisterResponse,
  TokenPair,
  User,
} from '../types';

export const authApi = {
  login: async (creds: LoginCredentials): Promise<TokenPair> => {
    const { data } = await apiClient.post<TokenPair>('/auth/login/', creds);
    return data;
  },

  register: async (creds: RegisterCredentials): Promise<RegisterResponse> => {
    const { data } = await apiClient.post<RegisterResponse>(
      '/auth/register/',
      creds,
    );
    return data;
  },

  getMe: async (): Promise<User> => {
    const { data } = await apiClient.get<User>('/users/me/');
    return data;
  },
};
