/**
 * Home page — public song feed.
 */

import { usePlayer } from '../context/PlayerContext';
import { SongList } from '../components/SongList';

export default function HomePage() {
  const { activeSong, playSong } = usePlayer();

  return (
    <section>
      <h2>Browse songs</h2>
      <SongList activeSong={activeSong} onPlay={playSong} />
    </section>
  );
}
