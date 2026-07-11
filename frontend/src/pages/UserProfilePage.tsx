/**
 * Public user profile — visit any user by username.
 *
 * Endpoints:
 *   GET /users/:username/        → public profile
 *   GET /users/:username/songs/  → their public songs
 *
 * fix: cards now wire into the global player (previously
 * read-only — see docs/frontend-audit.md).
 */

import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { getPublicProfile, getUserPublicSongs } from '../api/users';
import { SongCard } from '../components/SongCard';
import { usePlayer } from '../hooks/usePlayer';
import type { PublicProfile, Song } from '../types';

export default function UserProfilePage() {
  const { username } = useParams<{ username: string }>();
  const [profile, setProfile] = useState<PublicProfile | null>(null);
  const [songs, setSongs] = useState<Song[]>([]);
  const [loading, setLoading] = useState(true);
  const [notFound, setNotFound] = useState(false);

  const { currentSong, playSong } = usePlayer();

  useEffect(() => {
    if (!username) return;

    // Cleanup flag — prevents setState after unmount if user navigates away.
    let cancelled = false;

    const load = async () => {
      setLoading(true);
      setNotFound(false);
      try {
        // Fetch profile + songs in parallel.
        const [p, s] = await Promise.all([
          getPublicProfile(username),
          getUserPublicSongs(username),
        ]);
        if (!cancelled) {
          setProfile(p);
          setSongs(s);
        }
      } catch (err) {
        console.error(err);
        if (!cancelled) setNotFound(true);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    load();
    return () => {
      cancelled = true;
    };
  }, [username]);

  /* ── Loading ── */
  if (loading) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-8">
        <p className="text-[var(--text-muted)]">Loading…</p>
      </div>
    );
  }

  /* ── Not found ── */
  if (notFound || !profile) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-8 text-center">
        <p className="text-4xl mb-3">🔍</p>
        <p className="text-[var(--text-muted)] mb-4">User not found.</p>
        <Link to="/feed" className="text-[var(--brand)] hover:underline text-sm">
          ← Back to feed
        </Link>
      </div>
    );
  }

  const initials = (profile.display_name || profile.username).slice(0, 2).toUpperCase();

  /* ── Profile ── */
  return (
    <div className="max-w-4xl mx-auto px-4 py-8 pb-28">
      {/* Profile header card */}
      <div className="bg-[var(--surface-2)] border border-[var(--border)] rounded-2xl p-6 flex items-center gap-5 mb-8">
        {/* Avatar */}
        <div className="w-20 h-20 rounded-full bg-[var(--surface-3)] flex items-center justify-center overflow-hidden shrink-0">
          {profile.avatar ? (
            <img
              src={profile.avatar}
              alt={profile.display_name || profile.username}
              className="w-full h-full object-cover"
            />
          ) : (
            <span className="text-xl font-bold text-[var(--text-muted)]">
              {initials}
            </span>
          )}
        </div>

        {/* Info */}
        <div className="min-w-0">
          <h1 className="text-2xl font-bold truncate text-[var(--text)]">
            {profile.display_name || profile.username}
          </h1>
          <p className="text-[var(--text-muted)] text-sm">@{profile.username}</p>
          {profile.bio && (
            <p className="text-sm mt-2 text-[var(--text)]">{profile.bio}</p>
          )}
          <div className="flex gap-4 text-xs text-[var(--text-muted)] mt-3">
            <span>
              🎵 {profile.public_song_count}{' '}
              {profile.public_song_count === 1 ? 'song' : 'songs'}
            </span>
            <span>
              Joined{' '}
              {new Date(profile.created_at).toLocaleDateString(undefined, {
                year: 'numeric',
                month: 'long',
              })}
            </span>
          </div>
        </div>
      </div>

      {/* Songs section */}
      <h2 className="text-lg font-semibold text-[var(--text)] mb-4">Public songs</h2>

      {songs.length === 0 ? (
        <div className="text-center text-[var(--text-muted)] py-12">
          <p className="text-4xl mb-3">🎧</p>
          <p>No public songs yet.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {songs.map((song) => (
            <SongCard
              key={song.id}
              song={song}
              isActive={currentSong?.id === song.id}
              onPlay={(s) => playSong(s, songs)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
