/**
 * Home page — shows the user's songs.
 */

import { useSongs } from '../hooks/useSongs';
import { SongList } from '../components/SongList';

export function HomePage() {
  const { songs, isLoading, error, refetch } = useSongs();

  return (
    <div className="max-w-5xl mx-auto px-4 py-8 pb-28">
      <h1 className="text-2xl font-bold text-[var(--text)] mb-6">
        Your Library
      </h1>

      {isLoading && (
        <div className="text-center text-[var(--text-muted)] py-12">
          Loading songs…
        </div>
      )}

      {error && (
        <div className="text-center py-12">
          <p className="text-red-400 mb-3">{error}</p>
          <button
            onClick={refetch}
            className="px-4 py-2 rounded-lg bg-[var(--brand)] text-white text-sm hover:opacity-90"
          >
            Retry
          </button>
        </div>
      )}

      {!isLoading && !error && songs.length === 0 && (
        <div className="text-center text-[var(--text-muted)] py-12">
          <p className="text-lg mb-2">No songs yet 🎧</p>
          <p className="text-sm">Upload your first track to get started.</p>
        </div>
      )}

      {!isLoading && !error && songs.length > 0 && (
        <SongList songs={songs} />
      )}
    </div>
  );
}
