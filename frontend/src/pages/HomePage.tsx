import { usePlayer } from '../context/PlayerContext';
import { SongList } from '../components/SongList';

export default function HomePage() {
  const { activeSong, playSong } = usePlayer();

  return (
    <div>
      <div className="mb-8">
        <h2 className="text-2xl font-bold">Browse songs</h2>
        <p className="text-[var(--text-muted)] text-sm mt-1">
          Discover and play music from the community
        </p>
      </div>
      <SongList activeSong={activeSong} onPlay={playSong} />
    </div>
  );
}
