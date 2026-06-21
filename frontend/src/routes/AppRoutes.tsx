/**
 * Application route definitions.
 */

import { Routes, Route } from 'react-router-dom';
import HomePage from '../pages/HomePage';
import LoginPage from '../pages/LoginPage';
import RegisterPage from '../pages/RegisterPage';
import type { Song } from '../types';

interface AppRoutesProps {
  activeSong: Song | null;
  onPlay: (song: Song) => void;
}

export default function AppRoutes({ activeSong, onPlay }: AppRoutesProps) {
  return (
    <Routes>
      <Route
        path='/'
        element={<HomePage activeSong={activeSong} onPlay={onPlay} />}
      />
      <Route path='/login' element={<LoginPage />} />
      <Route path='/register' element={<RegisterPage />} />
      <Route
        path='*'
        element={<p style={{ padding: '2rem' }}>404 — Not found</p>}
      />
    </Routes>
  );
}
