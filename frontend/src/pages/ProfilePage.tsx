/**
 * Profile page — view and edit the authenticated user's profile.
 */

import { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import { authApi } from '../api/auth';
import type { User } from '../types';

export default function ProfilePage() {
  const { user, refreshUser } = useAuth();
  const [editing, setEditing] = useState(false);

  if (!user) {
    return (
      <div className="max-w-xl">
        <p className="text-[var(--text-muted)]">Loading profile…</p>
      </div>
    );
  }

  return (
    <div className="max-w-xl">
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">My profile</h2>
          <p className="text-[var(--text-muted)] text-sm mt-1">
            Your account information
          </p>
        </div>
        {!editing && (
          <button
            onClick={() => setEditing(true)}
            className="px-4 py-2 rounded-xl bg-[var(--surface-3)] hover:bg-[var(--surface-2)] text-sm font-medium transition-colors"
          >
            Edit
          </button>
        )}
      </div>

      {editing ? (
        <ProfileEditForm
          user={user}
          onDone={async () => {
            await refreshUser();
            setEditing(false);
          }}
          onCancel={() => setEditing(false)}
        />
      ) : (
        <ProfileView user={user} />
      )}
    </div>
  );
}

/* ───────────── Read-only view ───────────── */

function ProfileView({ user }: { user: User }) {
  return (
    <div className="bg-[var(--surface-2)] border border-[var(--border)] rounded-2xl p-6 flex flex-col gap-4">
      <div className="flex items-center gap-4 pb-4 border-b border-[var(--border)]">
        <div className="w-16 h-16 rounded-full bg-[var(--surface-3)] flex items-center justify-center text-3xl overflow-hidden">
          {user.avatar ? (
            <img
              src={user.avatar}
              alt={user.display_name || user.username}
              className="w-full h-full object-cover"
            />
          ) : (
            '🎵'
          )}
        </div>
        <div>
          <p className="font-bold text-lg">{user.display_name || user.username}</p>
          <p className="text-[var(--text-muted)] text-sm">@{user.username}</p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 text-sm">
        <div className="bg-[var(--surface-3)] rounded-xl p-3">
          <p className="text-[var(--text-muted)] text-xs mb-1">Email</p>
          <p className="font-medium truncate">{user.email || '—'}</p>
        </div>
        <div className="bg-[var(--surface-3)] rounded-xl p-3">
          <p className="text-[var(--text-muted)] text-xs mb-1">Songs</p>
          <p className="font-bold text-[var(--brand)]">{user.song_count ?? 0}</p>
        </div>
        <div className="bg-[var(--surface-3)] rounded-xl col-span-2 p-3">
          <p className="text-[var(--text-muted)] text-xs mb-1">Bio</p>
          <p>{user.bio || '—'}</p>
        </div>
      </div>
    </div>
  );
}

/* ───────────── Edit form ───────────── */

function ProfileEditForm({
  user,
  onDone,
  onCancel,
}: {
  user: User;
  onDone: () => void | Promise<void>;
  onCancel: () => void;
}) {
  const [displayName, setDisplayName] = useState(user.display_name || '');
  const [email, setEmail] = useState(user.email || '');
  const [bio, setBio] = useState(user.bio || '');
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(user.avatar);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setAvatarFile(file);
    setPreview(URL.createObjectURL(file));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    try {
      if (avatarFile) {
        await authApi.uploadAvatar(avatarFile);
      }
      await authApi.updateProfile({
        display_name: displayName,
        email,
        bio,
      });
      await onDone();
    } catch (err) {
      console.error(err);
      setError('Failed to save profile. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="bg-[var(--surface-2)] border border-[var(--border)] rounded-2xl p-6 flex flex-col gap-5"
    >
      {/* Avatar */}
      <div className="flex items-center gap-4 pb-4 border-b border-[var(--border)]">
        <div className="w-16 h-16 rounded-full bg-[var(--surface-3)] flex items-center justify-center text-3xl overflow-hidden">
          {preview ? (
            <img
              src={preview}
              alt="Avatar preview"
              className="w-full h-full object-cover"
            />
          ) : (
            '🎵'
          )}
        </div>
        <label className="px-4 py-2 rounded-xl bg-[var(--surface-3)] hover:bg-[var(--surface-2)] text-sm font-medium cursor-pointer transition-colors">
          Change avatar
          <input type="file" accept="image/*" hidden onChange={handleAvatarChange} />
        </label>
      </div>

      {/* Display name */}
      <div className="flex flex-col gap-1.5">
        <label className="text-xs text-[var(--text-muted)]">Display name</label>
        <input
          type="text"
          value={displayName}
          maxLength={150}
          onChange={(e) => setDisplayName(e.target.value)}
          className="bg-[var(--surface-3)] rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[var(--brand)]"
        />
      </div>

      {/* Email */}
      <div className="flex flex-col gap-1.5">
        <label className="text-xs text-[var(--text-muted)]">Email</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="bg-[var(--surface-3)] rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[var(--brand)]"
        />
      </div>

      {/* Bio */}
      <div className="flex flex-col gap-1.5">
        <label className="text-xs text-[var(--text-muted)]">Bio</label>
        <textarea
          value={bio}
          rows={4}
          maxLength={500}
          onChange={(e) => setBio(e.target.value)}
          className="bg-[var(--surface-3)] rounded-xl px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-[var(--brand)] resize-none"
        />
        <span className="text-xs text-[var(--text-muted)] self-end">
          {bio.length}/500
        </span>
      </div>

      {error && <p className="text-sm text-[var(--danger)]">{error}</p>}

      {/* Actions */}
      <div className="flex justify-end gap-3 pt-1">
        <button
          type="button"
          onClick={onCancel}
          disabled={saving}
          className="px-4 py-2 rounded-xl text-sm font-medium text-[var(--text-muted)] hover:text-[var(--text)] transition-colors disabled:opacity-50"
        >
          Cancel
        </button>
        <button
          type="submit"
          disabled={saving}
          className="px-4 py-2 rounded-xl bg-[var(--brand)] text-black font-semibold text-sm hover:bg-[var(--brand-dark)] transition-colors disabled:opacity-50"
        >
          {saving ? 'Saving…' : 'Save changes'}
        </button>
      </div>
    </form>
  );
}
