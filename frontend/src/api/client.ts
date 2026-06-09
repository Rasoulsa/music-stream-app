/**
 * Central Axios client for talking to the backend API.
 */

import axios from 'axios';

const baseURL =
  import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000/api';

export const apiClient = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});
