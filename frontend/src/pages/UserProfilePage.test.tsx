import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { PlayerProvider } from '../context/PlayerContext';
import { AudioPlayer } from '../components/AudioPlayer';
import UserProfilePage from './UserProfilePage';
import * as usersApi from '../api/users';
import type { PublicProfile, Song } from '../types';

vi.mock('../api/users');
const mockGetPublicProfile = vi.mocked(usersApi.getPublicProfile);
const mockGetUserPublicSongs = vi.mocked(usersApi.getUserPublicSongs);

const sampleProfile: PublicProfile = {
  username: 'faraz',
  display_name: 'Faraz',
  bio: 'Making beats.',
  avatar: null,
  public_song_count: 1,
  created_at: '2026-01-01T00:00:00Z',
};

const sampleSong: Song = {
  id: 1,
  title: 'Profile Track',
  artist: 'Faraz',
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

function renderProfile(username = 'faraz') {
  // See FeedPage.test.tsx for why PlayerProvider + AudioPlayer are
  // both needed here.
  return render(
    <MemoryRouter initialEntries={[`/users/${username}`]}>
      <PlayerProvider>
        <Routes>
          <Route path="/users/:username" element={<UserProfilePage />} />
        </Routes>
        <AudioPlayer />
      </PlayerProvider>
    </MemoryRouter>,
  );
}

describe('UserProfilePage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('renders the profile and their public songs', async () => {
    mockGetPublicProfile.mockResolvedValue(sampleProfile);
    mockGetUserPublicSongs.mockResolvedValue([sampleSong]);

    renderProfile();

    // "Faraz" legitimately appears twice on this page (the profile
    // heading AND the song card's artist link both say "Faraz") — so
    // this targets the heading specifically instead of guessing.
    await waitFor(() =>
      expect(screen.getByRole('heading', { name: 'Faraz' })).toBeInTheDocument(),
    );
    expect(screen.getByText('Profile Track')).toBeInTheDocument();
  });

  it('shows a not-found state when the profile fails to load', async () => {
    mockGetPublicProfile.mockRejectedValue(new Error('404'));
    mockGetUserPublicSongs.mockRejectedValue(new Error('404'));

    renderProfile('doesnotexist');

    await waitFor(() =>
      expect(screen.getByText(/user not found/i)).toBeInTheDocument(),
    );
  });

  // Stage 1 regression test — same bug class as FeedPage: public
  // profile song cards were previously read-only.
  it('plays a song when its card is clicked', async () => {
    mockGetPublicProfile.mockResolvedValue(sampleProfile);
    mockGetUserPublicSongs.mockResolvedValue([sampleSong]);

    renderProfile();

    const title = await screen.findByText('Profile Track');
    await userEvent.click(title);

    await waitFor(() => {
      expect(screen.getAllByText('Profile Track').length).toBeGreaterThan(1);
    });
  });
});
