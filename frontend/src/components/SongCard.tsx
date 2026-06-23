/**
 * Single song card with optional play button.
 *
 * isActive / onPlay are optional so the card can be used
 * in feed / profile pages without a player context.
 */

import { Link } from 'react-router-dom';
import type { Song } from '../types';
import { formatDuration } from '../utils/format';

interface SongCardProps {
  song: Song;
  isActive?: boolean; // optional — defaults to false
  onPlay?: (song: Song) => void; // optional — no-op if absent
}

export function SongCard({ song, isActive = false, onPlay }: SongCardProps) {
  return (
    <div
      className={`
        relative flex items-center gap-4 p-4 rounded-xl border transition-all group
        ${onPlay ? 'cursor-pointer' : 'cursor-default'}
        ${
          isActive
            ? 'bg-[var(--surface-3)] border-[var(--brand)]'
            : 'bg-[var(--surface-2)] border-[var(--border)] hover:border-[var(--surface-3)] hover:bg-[var(--surface-3)]'
        }
      `}
      onClick={() => onPlay?.(song)}
    >
      {/* Artwork */}
      <div className="flex-shrink-0 w-12 h-12 rounded-lg bg-[var(--surface-3)] overflow-hidden flex items-center justify-center text-2xl">
        {song.cover_image ? (
          <img
            src={song.cover_image}
            alt={`${song.title} cover`}
            className="w-full h-full object-cover"
          />
        ) : (
          <span>{isActive ? '▶️' : '🎵'}</span>
        )}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p
          className={`font-semibold truncate text-sm ${
            isActive ? 'text-[var(--brand)]' : 'text-[var(--text)]'
          }`}
        >
          {song.title}
        </p>

        {/* Owner — clickable link to their public profile */}
        <Link
          to={`/users/${song.owner}`}
          className="text-xs text-[var(--text-muted)] truncate mt-0.5 hover:text-[var(--brand)] transition-colors"
          onClick={(e) => e.stopPropagation()} // don't trigger onPlay
        >
          {song.artist || song.owner || 'Unknown artist'}
        </Link>
      </div>

      {/* Duration / play hint */}
      <div className="flex-shrink-0 text-xs text-[var(--text-muted)]">
        {song.duration_seconds ? (
          formatDuration(song.duration_seconds)
        ) : onPlay ? (
          <span className="opacity-0 group-hover:opacity-100 transition-opacity">
            ▶ Play
          </span>
        ) : null}
      </div>

      {isActive && (
        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-[var(--brand)] rounded-r-full" />
      )}
    </div>
  );
}
