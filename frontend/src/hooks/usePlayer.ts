import { createContext, useContext } from 'react';
import type { PlayerContextValue } from '../types/player';

export const PlayerContext = createContext<PlayerContextValue | undefined>(undefined);

export function usePlayer() {
  const ctx = useContext(PlayerContext);
  if (!ctx) {
    throw new Error('usePlayer must be used within a PlayerProvider');
  }
  return ctx;
}
