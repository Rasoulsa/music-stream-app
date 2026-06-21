import { useAuth } from '../hooks/useAuth';

export default function ProfilePage() {
  const { user } = useAuth();

  return (
    <div className="max-w-xl">
      <div className="mb-8">
        <h2 className="text-2xl font-bold">My profile</h2>
        <p className="text-[var(--text-muted)] text-sm mt-1">Your account information</p>
      </div>

      <div className="bg-[var(--surface-2)] border border-[var(--border)] rounded-2xl p-6 flex flex-col gap-4">
        <div className="flex items-center gap-4 pb-4 border-b border-[var(--border)]">
          <div className="w-16 h-16 rounded-full bg-[var(--surface-3)] flex items-center justify-center text-3xl">
            🎵
          </div>
          <div>
            <p className="font-bold text-lg">{user?.display_name || user?.username}</p>
            <p className="text-[var(--text-muted)] text-sm">@{user?.username}</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="bg-[var(--surface-3)] rounded-xl p-3">
            <p className="text-[var(--text-muted)] text-xs mb-1">Email</p>
            <p className="font-medium truncate">{user?.email || '—'}</p>
          </div>
          <div className="bg-[var(--surface-3)] rounded-xl p-3">
            <p className="text-[var(--text-muted)] text-xs mb-1">Songs</p>
            <p className="font-bold text-[var(--brand)]">{user?.song_count ?? 0}</p>
          </div>
          <div className="bg-[var(--surface-3)] rounded-xl col-span-2 p-3">
            <p className="text-[var(--text-muted)] text-xs mb-1">Bio</p>
            <p>{user?.bio || '—'}</p>
          </div>
        </div>

        <p className="text-xs text-[var(--text-muted)] text-center pt-2">
          Profile editing coming on Day 25
        </p>
      </div>
    </div>
  );
}
