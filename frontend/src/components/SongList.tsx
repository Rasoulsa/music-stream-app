/**
 * Fetches and displays the list of songs with search.
 */

import { useEffect, useState } from 'react';
import { getSongs } from '../api/songs';
import type { Song } from '../types';
import { SearchBar } from './SearchBar';
import { SongCard } from './SongCard';

interface SongListProps {
  activeSong: Song | null;
  onPlay: (song: Song) => void;
}

type Status = 'loading' | 'success' | 'error';

export function SongList({ activeSong, onPlay }: SongListProps) {
  const [songs, setSongs] = useState<Song[]>([]);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<Status>('loading');

  useEffect(() => {
    const timer = setTimeout(() => {
      setStatus('loading');
      getSongs({ search, ordering: '-created_at' })
        .then((data) => {
          setSongs(data.results);
          setStatus('success');
        })
        .catch(() => setStatus('error'));
    }, 400);

    return () => clearTimeout(timer);
  }, [search]);

  return (
    <div>
      <SearchBar value={search} onChange={setSearch} />

      {status === 'loading' && (
        <div className="flex flex-col gap-3">
          {[...Array(4)].map((_, i) => (
            <div
              key={i}
              className="h-20 rounded-xl bg-[var(--surface-2)] border border-[var(--border)] animate-pulse"
            />
          ))}
        </div>
      )}

      {status === 'error' && (
        <div className="flex items-center gap-3 p-4 rounded-xl bg-[var(--surface-2)] border border-[var(--danger)] text-[var(--danger)] text-sm">
          <span>❌</span>
          <span>Could not load songs. Is the backend running?</span>
        </div>
      )}

      {status === 'success' && songs.length === 0 && (
        <div className="text-center py-16 text-[var(--text-muted)]">
          <p className="text-4xl mb-3">🎵</p>
          <p className="font-medium">No songs found</p>
          <p className="text-sm mt-1">Try a different search term</p>
        </div>
      )}

      {status === 'success' && songs.length > 0 && (
        <div className="flex flex-col gap-2">
          {songs.map((song) => (
            <SongCard
              key={song.id}
              song={song}
              isActive={activeSong?.id === song.id}
              onPlay={onPlay}
            />
          ))}
        </div>
      )}
    </div>
  );
}
