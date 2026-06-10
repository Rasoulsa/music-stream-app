/**
 * Song API requests.
 */

import { apiClient } from './client';
import type { PaginatedResponse, Song } from '../types';

interface GetSongsParams {
  search?: string;
  ordering?: string;
}

export async function getSongs(
  params: GetSongsParams = {},
): Promise<PaginatedResponse<Song>> {
  const response = await apiClient.get<PaginatedResponse<Song>>('/songs/', {
    params,
  });
  return response.data;
}
