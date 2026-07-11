/**
 * Public feed — browse all public songs. Visible to everyone.
 *
 * Uses GET /feed/ (dedicated endpoint, cached on backend for default view).
 *
 * fix: cards now wire into the global player (previously
 * read-only — see docs/frontend-audit.md). Uses the currently-loaded
 * `songs` list as the play queue, same pattern as SongList.tsx.
 */

import { useEffect, useState, useCallback } from 'react';
import { getFeed } from '../api/songs';
import { SongCard } from '../components/SongCard';
import { usePlayer } from '../hooks/usePlayer';
import type { Song } from '../types';

export default function FeedPage() {
  const [songs, setSongs] = useState<Song[]>([]);
  const [search, setSearch] = useState('');
  const [ordering, setOrdering] = useState('-created_at');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const { currentSong, playSong } = usePlayer();

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getFeed({ search, ordering });
      setSongs(data.results);
    } catch (err) {
      console.error(err);
      setError('Failed to load feed.');
    } finally {
      setLoading(false);
    }
  }, [search, ordering]);

  // Debounce search by 350 ms so we don't hammer the API on every keystroke.
  useEffect(() => {
    const t = setTimeout(load, 350);
    return () => clearTimeout(t);
  }, [load]);

  return (
    <div className="max-w-5xl mx-auto px-4 py-8 pb-28">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-[var(--text)]">Discover</h1>
        <p className="text-[var(--text-muted)] text-sm mt-1">
          Browse public songs from the community
        </p>
      </div>

      {/* Controls */}
      <div className="flex flex-col sm:flex-row gap-3 mb-6">
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search songs, artists, albums…"
          className="flex-1 bg-[var(--surface-3)] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[var(--brand)]"
        />
        <select
          value={ordering}
          onChange={(e) => setOrdering(e.target.value)}
          className="bg-[var(--surface-3)] rounded-xl px-4 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[var(--brand)] cursor-pointer"
        >
          <option value="-created_at">Newest first</option>
          <option value="created_at">Oldest first</option>
          <option value="title">Title A–Z</option>
          <option value="-title">Title Z–A</option>
          <option value="artist">Artist A–Z</option>
          <option value="-duration_seconds">Longest first</option>
        </select>
      </div>

      {/* Loading */}
      {loading && (
        <div className="text-center text-[var(--text-muted)] py-12">Loading songs…</div>
      )}

      {/* Error */}
      {!loading && error && (
        <div className="text-center py-12">
          <p className="text-[var(--danger)] mb-3">{error}</p>
          <button
            onClick={load}
            className="px-4 py-2 rounded-lg bg-[var(--brand)] text-black text-sm font-medium hover:opacity-90"
          >
            Retry
          </button>
        </div>
      )}

      {/* Empty */}
      {!loading && !error && songs.length === 0 && (
        <div className="text-center text-[var(--text-muted)] py-12">
          <p className="text-4xl mb-3">🎶</p>
          <p className="text-lg mb-1">
            {search ? 'No songs match your search.' : 'No public songs yet.'}
          </p>
          {search && (
            <button
              onClick={() => setSearch('')}
              className="text-sm text-[var(--brand)] hover:underline mt-1"
            >
              Clear search
            </button>
          )}
        </div>
      )}

      {/* Grid — Stage 1 fix: cards are now playable, wired to the
          global player queue using the currently-loaded feed list. */}
      {!loading && !error && songs.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {songs.map((song) => (
            <SongCard
              key={song.id}
              song={song}
              isActive={currentSong?.id === song.id}
              onPlay={(s) => playSong(s, songs)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
