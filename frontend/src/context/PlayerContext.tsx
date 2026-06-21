/**
 * Player state shared across all pages (so SongList anywhere can
 * trigger playback in the persistent AudioPlayer).
 */

import { createContext, useContext } from 'react';
import type { Song } from '../types';

interface PlayerContextValue {
  activeSong: Song | null;
  playSong: (song: Song) => void;
}

export const PlayerContext = createContext<PlayerContextValue | null>(null);
export function usePlayer() {
  const ctx = useContext(PlayerContext);
  if (!ctx) {
    throw new Error('usePlayer must be used within <Layout>');
  }
  return ctx;
}
