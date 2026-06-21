/**
 * A fixed audio player bar for the currently selected song.
 */

import type { Song } from '../types';

interface AudioPlayerProps {
  song: Song | null;
}

export function AudioPlayer({ song }: AudioPlayerProps) {
  if (!song) {
    return null;
  }

  return (
    <div className="audio-player">
      <div className="audio-player__info">
        {song.cover_image ? (
          <img
            src={song.cover_image}
            alt={`${song.title} cover`}
            className="audio-player__cover"
          />
        ) : (
          <div className="audio-player__cover audio-player__cover--empty">
            🎵
          </div>
        )}
        <div>
          <div className="audio-player__title">{song.title}</div>
          <div className="audio-player__artist">
            {song.artist || song.owner || 'Unknown artist'}
          </div>
        </div>
      </div>

      <audio
        key={song.id}
        src={song.audio_file}
        controls
        autoPlay
        className="audio-player__controls"
      >
        Your browser does not support the audio element.
      </audio>
    </div>
  );
}
