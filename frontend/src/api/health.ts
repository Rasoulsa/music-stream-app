/**
 * Health check API requests.
 *
 * Note: /health/ is intentionally unversioned (/api/health/),
 * so it does NOT use the versioned apiClient base URL.
 */

import axios from 'axios';
import type { HealthResponse } from '../types';

const apiBase = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000/api/v1';

const healthURL = `${apiBase.replace(/\/v1$/, '')}/health/`;

export async function getHealth(): Promise<HealthResponse> {
  const response = await axios.get<HealthResponse>(healthURL);
  return response.data;
}
