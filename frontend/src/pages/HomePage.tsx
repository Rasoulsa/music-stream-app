/**
 * Home page — song list with backend connectivity indicator.
 */

import { HealthCheck } from '../components/HealthCheck';
import { SongList } from '../components/SongList';
import type { Song } from '../types';

interface HomePageProps {
  activeSong: Song | null;
  onPlay: (song: Song) => void;
}

export default function HomePage({ activeSong, onPlay }: HomePageProps) {
  return (
    <main>
      <HealthCheck />
      <SongList activeSong={activeSong} onPlay={onPlay} />
    </main>
  );
}
