/**
 * Single song card with play button.
 */

import type { Song } from '../types';

interface SongCardProps {
  song: Song;
  isActive: boolean;
  onPlay: (song: Song) => void;
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
      {/* Artwork placeholder */}
      <div className="flex-shrink-0 w-12 h-12 rounded-lg bg-[var(--surface-3)] flex items-center justify-center text-2xl">
        {isActive ? '▶️' : '🎵'}
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <p className={`font-semibold truncate text-sm ${isActive ? 'text-[var(--brand)]' : 'text-[var(--text)]'}`}>
          {song.title}
        </p>
        <p className="text-xs text-[var(--text-muted)] truncate mt-0.5">
          {song.artist || song.uploaded_by || 'Unknown artist'}
        </p>
      </div>

      {/* Duration / play hint */}
      <div className="flex-shrink-0 text-xs text-[var(--text-muted)]">
        {song.duration
          ? `${Math.floor(song.duration / 60)}:${String(song.duration % 60).padStart(2, '0')}`
          : <span className="opacity-0 group-hover:opacity-100 transition-opacity">▶ Play</span>
        }
      </div>

      {isActive && (
        <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-[var(--brand)] rounded-r-full" />
      )}
    </div>
  );
}
