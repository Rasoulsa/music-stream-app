/**
 * Fetches the authenticated user's song list.
 * Returns data + loading + error states.
 */

import { useState, useEffect, useCallback } from 'react';
import { apiClient } from '../api/client';
import type { Song, PaginatedResponse } from '../types';

interface UseSongsResult {
  songs: Song[];
  isLoading: boolean;
  error: string | null;
  refetch: () => void;
}

export function useSongs(): UseSongsResult {
  const [songs, setSongs] = useState<Song[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSongs = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await apiClient.get<PaginatedResponse<Song>>('/songs/');
      setSongs(res.data.results);
    } catch (err) {
      console.error('Failed to fetch songs:', err);
      setError('Could not load songs. Please try again.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSongs();
  }, [fetchSongs]);

  return { songs, isLoading, error, refetch: fetchSongs };
}
