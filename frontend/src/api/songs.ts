/**
 * Song API requests.
 */

import { apiClient } from './client';
import type { PaginatedResponse, Song } from '../types';

export interface GetSongsParams {
  search?: string;
  ordering?: string;
}

// Authenticated user's own songs (home page).
export async function getSongs(
  params: GetSongsParams = {},
): Promise<PaginatedResponse<Song>> {
  const response = await apiClient.get<PaginatedResponse<Song>>('/songs/', {
    params,
  });
  return response.data;
}

// Public feed — all public songs. No auth required.
// Uses the dedicated /feed/ endpoint (cached on backend for default view).
export async function getFeed(
  params: GetSongsParams = {},
): Promise<PaginatedResponse<Song>> {
  const response = await apiClient.get<PaginatedResponse<Song>>('/feed/', {
    params,
  });
  return response.data;
}

export interface UploadSongPayload {
  title: string;
  artist?: string;
  album?: string;
  audio_file: File;
  cover_image?: File | null;
  is_public: boolean;
}

export async function uploadSong(
  payload: UploadSongPayload,
  onProgress?: (percent: number) => void,
): Promise<Song> {
  const form = new FormData();
  form.append('title', payload.title);
  if (payload.artist) form.append('artist', payload.artist);
  if (payload.album) form.append('album', payload.album);
  form.append('audio_file', payload.audio_file);
  if (payload.cover_image) form.append('cover_image', payload.cover_image);
  form.append('is_public', String(payload.is_public));

  const response = await apiClient.post<Song>('/songs/', form, {
    headers: { 'Content-Type': 'multipart/form-data' },
    onUploadProgress: (e) => {
      if (onProgress && e.total) {
        onProgress(Math.round((e.loaded / e.total) * 100));
      }
    },
  });
  return response.data;
}
