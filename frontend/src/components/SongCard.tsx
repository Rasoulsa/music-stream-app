/**
 * Displays a single song as a clickable card.
 */

import type { Song } from '../types';
import { formatDuration } from '../utils/format';

interface SongCardProps {
  song: Song;
  isActive: boolean;
  onPlay: (song: Song) => void;
}

export function SongCard({ song, isActive, onPlay }: SongCardProps) {
  return (
    <button
      type="button"
      className={`song-card ${isActive ? 'song-card--active' : ''}`}
      onClick={() => onPlay(song)}
    >
      <div className="song-card__cover">
        {song.cover_image ? (
          <img src={song.cover_image} alt={`${song.title} cover`} />
        ) : (
          <div className="song-card__placeholder">🎵</div>
        )}
      </div>
      <div className="song-card__info">
        <span className="song-card__title">{song.title}</span>
        <span className="song-card__artist">{song.artist}</span>
        {song.album && <span className="song-card__album">{song.album}</span>}
      </div>
      <span className="song-card__duration">
        {formatDuration(song.duration_seconds)}
      </span>
    </button>
  );
}
