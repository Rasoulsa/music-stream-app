/**
 * Current user's profile — placeholder. Edit UI built on Day 25.
 */

import { useAuth } from '../hooks/useAuth';

export default function ProfilePage() {
  const { user } = useAuth();

  return (
    <section>
      <h2>My profile</h2>
      <ul style={{ lineHeight: 1.8 }}>
        <li>Username: {user?.username}</li>
        <li>Display name: {user?.display_name || '—'}</li>
        <li>Bio: {user?.bio || '—'}</li>
        <li>Songs: {user?.song_count ?? 0}</li>
      </ul>
      <p style={{ color: '#888' }}>Edit form coming on Day 25.</p>
    </section>
  );
}
