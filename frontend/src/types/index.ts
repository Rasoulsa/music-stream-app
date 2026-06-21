/**
 * Shared TypeScript types for the application.
 */

// Response from GET /api/health/
export interface HealthResponse {
  status: string;
  service: string;
  cache?: string;
}

// ─── Auth & User ──────────────────────────────────────

export interface User {
  username: string;
  email: string;
  display_name: string;
  bio: string;
  avatar: string | null;
  song_count: number;
  created_at: string;
  updated_at: string;
}

export interface LoginCredentials {
  username: string;
  password: string;
}

export interface RegisterCredentials {
  username: string;
  email?: string;
  password: string;
}

export interface TokenPair {
  access: string;
  refresh: string;
}

export interface RegisterResponse {
  id: number;
  username: string;
  email: string;
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
