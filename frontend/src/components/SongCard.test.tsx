import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { SongCard } from './SongCard';
import type { Song } from '../types';

// Full Song fixture — matches the real type (album, audio_file, status…).
const baseSong: Song = {
  id: 1,
  title: 'Midnight Drive',
  artist: 'The Synths',
  album: 'Neon Nights',
  audio_file: 'http://example.com/song.mp3',
  cover_image: null,
  duration_seconds: 125,
  owner: 'faraz',
  is_public: true,
  status: 'ready',
  created_at: '2026-06-23T00:00:00Z',
  updated_at: '2026-06-23T00:00:00Z',
};

function renderCard(props: Partial<React.ComponentProps<typeof SongCard>> = {}) {
  return render(
    <MemoryRouter>
      <SongCard song={baseSong} {...props} />
    </MemoryRouter>,
  );
}

describe('SongCard', () => {
  it('renders the song title', () => {
    renderCard();
    expect(screen.getByText('Midnight Drive')).toBeInTheDocument();
  });

  it('renders the artist name', () => {
    renderCard();
    expect(screen.getByText('The Synths')).toBeInTheDocument();
  });

  it('formats and shows the duration', () => {
    renderCard();
    expect(screen.getByText('2:05')).toBeInTheDocument();
  });

  it('links the owner/artist to their profile', () => {
    renderCard();
    const link = screen.getByText('The Synths').closest('a');
    expect(link).toHaveAttribute('href', '/users/faraz');
  });

  it('calls onPlay when clicked', async () => {
    const onPlay = vi.fn();
    renderCard({ onPlay });
    await userEvent.click(screen.getByText('Midnight Drive'));
    expect(onPlay).toHaveBeenCalledTimes(1);
  });

  it('does not crash when clicked without onPlay (read-only mode)', async () => {
    renderCard(); // no onPlay
    await userEvent.click(screen.getByText('Midnight Drive'));
    expect(screen.getByText('Midnight Drive')).toBeInTheDocument();
  });
});
