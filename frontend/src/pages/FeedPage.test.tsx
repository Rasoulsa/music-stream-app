import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
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
  return render(
    <MemoryRouter>
      <FeedPage />
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
});
