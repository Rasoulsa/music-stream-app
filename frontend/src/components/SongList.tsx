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

  // Debounce: wait 400ms after typing stops before calling the API.
  useEffect(() => {
    const timer = setTimeout(() => {
      setStatus('loading');
      getSongs({ search, ordering: '-created_at' })
        .then((data) => {
          setSongs(data.results);
          setStatus('success');
        })
        .catch(() => {
          setStatus('error');
        });
    }, 400);

    return () => clearTimeout(timer);
  }, [search]);

  return (
    <div className="song-list">
      <SearchBar value={search} onChange={setSearch} />

      {status === 'loading' && <p>Loading songs...</p>}

      {status === 'error' && (
        <p style={{ color: 'red' }}>
          ❌ Could not load songs. Is the backend running?
        </p>
      )}

      {status === 'success' && songs.length === 0 && (
        <p>No songs found. Try a different search.</p>
      )}

      {status === 'success' && songs.length > 0 && (
        <div className="song-list__grid">
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
