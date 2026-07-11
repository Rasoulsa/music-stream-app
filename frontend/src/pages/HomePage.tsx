/**
 * Home page — shows the authenticated user's songs.
 *
 * After logout, private songs are immediately removed from the rendered
 * list while public songs may remain visible.
 */

import { SongList } from '../components/SongList';
import { useAuth } from '../hooks/useAuth';
import { useSongs } from '../hooks/useSongs';

export function HomePage() {
  const { isAuthenticated } = useAuth();
  const { songs, isLoading, error, refetch } = useSongs();

  // The song request might have completed while the user was authenticated.
  // Filtering at render time prevents those cached private songs from
  // remaining visible after the authentication state is cleared.
  const visibleSongs = isAuthenticated ? songs : songs.filter((song) => song.is_public);

  return (
    <div className="max-w-5xl mx-auto px-4 py-8 pb-28">
      <h1 className="text-2xl font-bold text-[var(--text)] mb-6">
        {isAuthenticated ? 'Your Library' : 'Public Songs'}
      </h1>

      {isLoading && (
        <div className="text-center text-[var(--text-muted)] py-12">Loading songs…</div>
      )}

      {error && (
        <div className="text-center py-12">
          <p className="text-red-400 mb-3">{error}</p>
          <button
            type="button"
            onClick={refetch}
            className="px-4 py-2 rounded-lg bg-[var(--brand)] text-white text-sm hover:opacity-90"
          >
            Retry
          </button>
        </div>
      )}

      {!isLoading && !error && visibleSongs.length === 0 && (
        <div className="text-center text-[var(--text-muted)] py-12">
          <p className="text-lg mb-2">
            {isAuthenticated ? 'No songs yet 🎧' : 'No public songs available 🎧'}
          </p>

          <p className="text-sm">
            {isAuthenticated
              ? 'Upload your first track to get started.'
              : 'Log in to view your private library.'}
          </p>
        </div>
      )}

      {!isLoading && !error && visibleSongs.length > 0 && (
        <SongList songs={visibleSongs} />
      )}
    </div>
  );
}
