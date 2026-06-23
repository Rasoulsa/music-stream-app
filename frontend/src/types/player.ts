import type { Song } from './index';

export interface PlayerContextValue {
  currentSong: Song | null;
  queue: Song[];
  isPlaying: boolean;
  playSong: (song: Song, queue?: Song[]) => void;
  togglePlay: () => void;
  playNext: () => void;
  playPrev: () => void;
  setIsPlaying: (value: boolean) => void;
}
