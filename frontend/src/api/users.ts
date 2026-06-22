/**
 * Public user/profile reads — no auth required.
 *
 * Endpoints (from backend/music/urls.py):
 *   GET /users/:username/        → PublicProfileView
 *   GET /users/:username/songs/  → UserPublicSongsView
 */

import { apiClient } from './client';
import type { PaginatedResponse, PublicProfile, Song } from '../types';

export async function getPublicProfile(
  username: string,
): Promise<PublicProfile> {
  const { data } = await apiClient.get<PublicProfile>(`/users/${username}/`);
  return data;
}

export async function getUserPublicSongs(username: string): Promise<Song[]> {
  const { data } = await apiClient.get<PaginatedResponse<Song>>(
    `/users/${username}/songs/`,
  );
  return data.results;
}
