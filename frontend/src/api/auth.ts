/**
 * Auth API calls.
 */

import { apiClient } from './client';
import type {
  LoginCredentials,
  RegisterCredentials,
  RegisterResponse,
  TokenPair,
  UpdateProfilePayload,
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

  // Update text fields (JSON PATCH).
  updateProfile: async (payload: UpdateProfilePayload): Promise<User> => {
    const { data } = await apiClient.patch<User>('/users/me/', payload);
    return data;
  },

  // Upload avatar (multipart PATCH).
  uploadAvatar: async (file: File): Promise<User> => {
    const formData = new FormData();
    formData.append('avatar', file);
    const { data } = await apiClient.patch<User>('/users/me/', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return data;
  },
};
