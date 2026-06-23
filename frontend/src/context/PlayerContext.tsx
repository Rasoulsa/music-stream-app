/**
 * Global audio player state.
 *
 * Holds the current song + the full queue so the player
 * persists across route navigation and supports next/prev.
 *
 * Context object + usePlayer hook live in src/hooks/usePlayer.ts
 * so this file only exports a component (react-refresh rule).
 */

import { useState, useCallback } from 'react';
import type { ReactNode } from 'react';
import type { Song } from '../types';
import { PlayerContext } from '../hooks/usePlayer';

export function PlayerProvider({ children }: { children: ReactNode }) {
  const [currentSong, setCurrentSong] = useState<Song | null>(null);
  const [queue, setQueue] = useState<Song[]>([]);
  const [isPlaying, setIsPlaying] = useState(false);

  const playSong = useCallback((song: Song, newQueue?: Song[]) => {
    setCurrentSong(song);
    if (newQueue) {
      setQueue(newQueue);
    }
    setIsPlaying(true);
  }, []);

  const togglePlay = useCallback(() => {
    setIsPlaying((prev) => !prev);
  }, []);

  const playNext = useCallback(() => {
    if (!currentSong || queue.length === 0) return;
    const idx = queue.findIndex((s) => s.id === currentSong.id);
    const next = queue[idx + 1];
    if (next) {
      setCurrentSong(next);
      setIsPlaying(true);
    }
  }, [currentSong, queue]);

  const playPrev = useCallback(() => {
    if (!currentSong || queue.length === 0) return;
    const idx = queue.findIndex((s) => s.id === currentSong.id);
    const prev = queue[idx - 1];
    if (prev) {
      setCurrentSong(prev);
      setIsPlaying(true);
    }
  }, [currentSong, queue]);

  return (
    <PlayerContext.Provider
      value={{
        currentSong,
        queue,
        isPlaying,
        playSong,
        togglePlay,
        playNext,
        playPrev,
        setIsPlaying,
      }}
    >
      {children}
    </PlayerContext.Provider>
  );
}
