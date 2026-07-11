import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter } from 'react-router-dom';
import { PlayerProvider } from '../context/PlayerContext';
import { AudioPlayer } from '../components/AudioPlayer';
import FeedPage from './FeedPage';
import * as songsApi from '../api/songs';
import type { Song } from '../types';

vi.mock('../api/songs');
const mockGetFeed = vi.mocked(songsApi.getFeed);

const sampleSong: Song = {
  id: 1,
  title: 'Public Track',
  artist: 'Some Artist',
  album: 'Album',
  audio_file: 'http://example.com/a.mp3',
  cover_image: null,
  duration_seconds: 60,
  owner: 'faraz',
  is_public: true,
  status: 'ready',
  created_at: '2026-06-23T00:00:00Z',
  updated_at: '2026-06-23T00:00:00Z',
};

function renderFeed() {
  // Stage 1: FeedPage now calls usePlayer(), which throws outside a
  // PlayerProvider — so the test harness needs one, same as the real
  // app tree. AudioPlayer is rendered alongside it (as Layout.tsx does
  // in the real app) so the "plays a song" test below can observe the
  // persistent player bar actually appearing — AudioPlayer renders
  // null until a currentSong exists, so it's a no-op for every other
  // test in this file.
  return render(
    <MemoryRouter>
      <PlayerProvider>
        <FeedPage />
        <AudioPlayer />
      </PlayerProvider>
    </MemoryRouter>,
  );
}

describe('FeedPage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('renders songs returned by the feed', async () => {
    mockGetFeed.mockResolvedValue({
      count: 1,
      next: null,
      previous: null,
      results: [sampleSong],
    });

    renderFeed();

    // waitFor covers the 350ms debounce + async resolve.
    await waitFor(() => expect(screen.getByText('Public Track')).toBeInTheDocument());
  });

  it('shows the empty state when there are no songs', async () => {
    mockGetFeed.mockResolvedValue({
      count: 0,
      next: null,
      previous: null,
      results: [],
    });

    renderFeed();

    await waitFor(() =>
      expect(screen.getByText(/no public songs yet/i)).toBeInTheDocument(),
    );
  });

  it('shows an error state when the request fails', async () => {
    mockGetFeed.mockRejectedValue(new Error('network'));

    renderFeed();

    await waitFor(() =>
      expect(screen.getByText(/failed to load feed/i)).toBeInTheDocument(),
    );
  });

  // Stage 1 regression test: this is the actual bug being fixed —
  // feed cards were previously read-only (no onPlay wired). Clicking
  // a card should start playback and the persistent player bar
  // (AudioPlayer, rendered null until a currentSong exists) should
  // appear with the same track's title.
  it('plays a song when its card is clicked', async () => {
    mockGetFeed.mockResolvedValue({
      count: 1,
      next: null,
      previous: null,
      results: [sampleSong],
    });

    renderFeed();

    const title = await screen.findByText('Public Track');
    await userEvent.click(title);

    // Now that AudioPlayer is in the tree, "Public Track" should
    // appear twice: once in the card, once in the player bar.
    await waitFor(() => {
      expect(screen.getAllByText('Public Track').length).toBeGreaterThan(1);
    });
  });
});
