/**
 * Single song card with play button.
 */

import type { Song } from '../types';

interface SongCardProps {
  song: Song;
  isActive: boolean;
  onPlay: (song: Song) => void;
}

function formatDuration(seconds: number): string {
  if (!seconds) return '';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}

export function SongCard({ song, isActive, onPlay }: SongCardProps) {
  return (
    <div
      className={`
        relative flex items-center gap-4 p-4 rounded-xl border transition-all cursor-pointer group
        ${isActive
          ? 'bg-[var(--surface-3)] border-[var(--brand)]'
          : 'bg-[var(--surface-2)] border-[var(--border)] hover:border-[var(--surface-3)] hover:bg-[var(--surface-3)]'
        }
      `}
      onClick={() => onPlay(song)}
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
        <p className={`font-semibold truncate text-sm ${isActive ? 'text-[var(--brand)]' : 'text-[var(--text)]'}`}>
          {song.title}
        </p>
        <p className="text-xs text-[var(--text-muted)] truncate mt-0.5">
          {song.artist || song.owner || 'Unknown artist'}
        </p>
      </div>

      {/* Duration / play hint */}
      <div className="flex-shrink-0 text-xs text-[var(--text-muted)]">
        {song.duration_seconds
          ? formatDuration(song.duration_seconds)
          : <span className="opacity-0 group-hover:opacity-100 transition-opacity">▶ Play</span>
        }
      </div>

      {isActive && (
        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-[var(--brand)] rounded-r-full" />
      )}
    </div>
  );
}
