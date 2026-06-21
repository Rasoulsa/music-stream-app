/**
 * Shared TypeScript types for the application.
 */

// Response from GET /api/health/
export interface HealthResponse {
  status: string;
  service: string;
  cache?: string;
}

// A single Song from the backend
export interface Song {
  id: number;
  title: string;
  artist: string;
  album: string;
  audio_file: string;
  cover_image: string | null;
  duration_seconds: number;
  created_at: string;
  updated_at: string;
}

// DRF paginated list response
export interface PaginatedResponse<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}
