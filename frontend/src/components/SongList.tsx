/**
 * Renders a list of songs and wires play actions to the global player.
 */

import type { Song } from '../types';
import { SongCard } from './SongCard';
import { usePlayer } from '../context/PlayerContext';

interface SongListProps {
  songs: Song[];
}

export function SongList({ songs }: SongListProps) {
  const { currentSong, playSong } = usePlayer();

  return (
    <div className="flex flex-col gap-3">
      {songs.map((song) => (
        <SongCard
          key={song.id}
          song={song}
          isActive={currentSong?.id === song.id}
          onPlay={(s) => playSong(s, songs)}
        />
      ))}
    </div>
  );
}
