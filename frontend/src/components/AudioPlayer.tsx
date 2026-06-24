/**
 * Persistent global audio player bar.
 * Reads the current song from PlayerContext and stays mounted
 * across route changes so playback is uninterrupted.
 */

import { useRef, useEffect, useState } from 'react';
import { usePlayer } from '../hooks/usePlayer';

function formatTime(seconds: number): string {
  if (!seconds || isNaN(seconds)) return '0:00';
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

function resolveAudioSrc(song: any): string {
  const raw =
    song?.audio_file ||
    song?.audio_url ||
    song?.file ||
    '';

  if (!raw) return '';

  // Already absolute or root-relative
  if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('/')) {
    return raw;
  }

  // If API returns only object key:
  // songs/audio/file.mp3 -> /music-media/songs/audio/file.mp3
  return `/music-media/${raw}`;
}

export function AudioPlayer() {
  const { currentSong, isPlaying, setIsPlaying, togglePlay, playNext, playPrev } =
    usePlayer();

  const audioRef = useRef<HTMLAudioElement>(null);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [volume, setVolume] = useState(1);

  const audioSrc = currentSong ? resolveAudioSrc(currentSong) : '';

  // Debug current song/source
  useEffect(() => {
    if (!currentSong) return;

    console.log('[AudioPlayer] currentSong:', currentSong);
    console.log('[AudioPlayer] resolved audioSrc:', audioSrc);
  }, [currentSong, audioSrc]);

  // When song/source changes, force audio element to reload.
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio || !audioSrc) return;

    audio.load();

    if (isPlaying) {
      audio.play().catch((err) => {
        console.error('[AudioPlayer] play() failed after src change:', err);
        console.error('[AudioPlayer] audio src:', audio.currentSrc || audio.src);
        console.error('[AudioPlayer] audio error:', audio.error);
        setIsPlaying(false);
      });
    }
  }, [audioSrc, isPlaying, setIsPlaying]);

  // Sync play/pause state with the <audio> element.
  useEffect(() => {
    const audio = audioRef.current;
    if (!audio || !audioSrc) return;

    if (isPlaying) {
      audio.play().catch((err) => {
        console.error('[AudioPlayer] play() failed:', err);
        console.error('[AudioPlayer] src:', audio.currentSrc || audio.src);
        console.error('[AudioPlayer] error:', audio.error);
        setIsPlaying(false);
      });
    } else {
      audio.pause();
    }
  }, [isPlaying, audioSrc, setIsPlaying]);

  // Apply volume
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume;
    }
  }, [volume]);

  if (!currentSong) {
    return null;
  }

  const handleSeek = (e: React.ChangeEvent<HTMLInputElement>) => {
    const time = Number(e.target.value);
    if (audioRef.current) {
      audioRef.current.currentTime = time;
      setCurrentTime(time);
    }
  };

  return (
    <div className="fixed bottom-0 left-0 right-0 z-50 bg-[var(--surface-2)] border-t border-[var(--border)] px-4 py-3">
      <div className="max-w-5xl mx-auto flex items-center gap-4">
        {/* Track info */}
        <div className="flex items-center gap-3 w-1/4 min-w-0">
          <div className="w-12 h-12 rounded-lg bg-[var(--surface-3)] overflow-hidden flex items-center justify-center text-xl flex-shrink-0">
            {currentSong.cover_image ? (
              <img
                src={currentSong.cover_image}
                alt={`${currentSong.title} cover`}
                className="w-full h-full object-cover"
              />
            ) : (
              <span>🎵</span>
            )}
          </div>

          <div className="min-w-0">
            <div className="text-sm font-semibold text-[var(--text)] truncate">
              {currentSong.title}
            </div>
            <div className="text-xs text-[var(--text-muted)] truncate">
              {currentSong.artist || currentSong.owner || 'Unknown artist'}
            </div>
          </div>
        </div>

        {/* Controls + progress */}
        <div className="flex-1 flex flex-col items-center gap-1">
          <div className="flex items-center gap-4">
            <button
              onClick={playPrev}
              className="text-[var(--text-muted)] hover:text-[var(--text)] transition-colors"
              aria-label="Previous"
            >
              ⏮
            </button>

            <button
              onClick={togglePlay}
              className="w-9 h-9 rounded-full bg-[var(--brand)] text-white flex items-center justify-center hover:opacity-90 transition-opacity"
              aria-label={isPlaying ? 'Pause' : 'Play'}
            >
              {isPlaying ? '⏸' : '▶'}
            </button>

            <button
              onClick={playNext}
              className="text-[var(--text-muted)] hover:text-[var(--text)] transition-colors"
              aria-label="Next"
            >
              ⏭
            </button>
          </div>

          <div className="flex items-center gap-2 w-full">
            <span className="text-[10px] text-[var(--text-muted)] w-8 text-right">
              {formatTime(currentTime)}
            </span>

            <input
              type="range"
              min={0}
              max={duration || 0}
              value={currentTime}
              onChange={handleSeek}
              className="flex-1 h-1 accent-[var(--brand)] cursor-pointer"
            />

            <span className="text-[10px] text-[var(--text-muted)] w-8">
              {formatTime(duration)}
            </span>
          </div>
        </div>

        {/* Volume */}
        <div className="hidden sm:flex items-center gap-2 w-1/6">
          <span className="text-sm">🔊</span>

          <input
            type="range"
            min={0}
            max={1}
            step={0.05}
            value={volume}
            onChange={(e) => setVolume(Number(e.target.value))}
            className="flex-1 h-1 accent-[var(--brand)] cursor-pointer"
          />
        </div>

        {/* Hidden audio element */}
        <audio
          key={currentSong.id}
          ref={audioRef}
          src={audioSrc}
          preload="metadata"
          onLoadedMetadata={(e) => {
            console.log('[AudioPlayer] metadata loaded:', e.currentTarget.duration);
            setDuration(e.currentTarget.duration);
          }}
          onCanPlay={() => {
            console.log('[AudioPlayer] can play:', audioSrc);
          }}
          onTimeUpdate={(e) => setCurrentTime(e.currentTarget.currentTime)}
          onEnded={playNext}
          onError={(e) => {
            const audio = e.currentTarget;
            console.error('[AudioPlayer] audio element error');
            console.error('[AudioPlayer] src:', audio.currentSrc || audio.src);
            console.error('[AudioPlayer] error:', audio.error);
            setIsPlaying(false);
          }}
        />
      </div>
    </div>
  );
}
