/**
 * Top navigation bar — auth-aware.
 */

import { Link, NavLink } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

export default function Navbar() {
  const { user, isAuthenticated, isLoading, logout } = useAuth();

  return (
    <header className="sticky top-0 z-50 flex items-center justify-between px-6 py-3 bg-[var(--surface-2)] border-b border-[var(--border)]">
      <Link to="/" className="flex items-center gap-2 no-underline">
        <span className="text-2xl">🎵</span>
        <span className="font-bold text-lg text-[var(--text)]">MusicStream</span>
      </Link>

      <nav className="flex items-center gap-6 text-sm">
        <NavLink
          to="/"
          end
          className={({ isActive }) =>
            isActive
              ? 'text-[var(--brand)] font-semibold'
              : 'text-[var(--text-muted)] hover:text-[var(--text)] transition-colors'
          }
        >
          Home
        </NavLink>

        {!isLoading && (
          isAuthenticated ? (
            <>
              <NavLink
                to="/upload"
                className={({ isActive }) =>
                  isActive
                    ? 'text-[var(--brand)] font-semibold'
                    : 'text-[var(--text-muted)] hover:text-[var(--text)] transition-colors'
                }
              >
                Upload
              </NavLink>

              <NavLink
                to="/profile"
                className={({ isActive }) =>
                  isActive
                    ? 'text-[var(--brand)] font-semibold'
                    : 'text-[var(--text-muted)] hover:text-[var(--text)] transition-colors'
                }
              >
                Profile
              </NavLink>

              <div className="flex items-center gap-3 ml-2 pl-4 border-l border-[var(--border)]">
                <span className="text-[var(--text-muted)] text-xs">
                  {user?.display_name || user?.username}
                </span>
                <button
                  onClick={logout}
                  className="px-3 py-1.5 rounded-md text-xs bg-[var(--surface-3)] text-[var(--text-muted)] hover:text-[var(--danger)] hover:border-[var(--danger)] border border-[var(--border)] transition-colors"
                >
                  Log out
                </button>
              </div>
            </>
          ) : (
            <>
              <NavLink
                to="/login"
                className={({ isActive }) =>
                  isActive
                    ? 'text-[var(--brand)] font-semibold'
                    : 'text-[var(--text-muted)] hover:text-[var(--text)] transition-colors'
                }
              >
                Log in
              </NavLink>
              <Link
                to="/register"
                className="px-4 py-1.5 rounded-md bg-[var(--brand)] text-black font-semibold text-xs hover:bg-[var(--brand-dark)] transition-colors"
              >
                Register
              </Link>
            </>
          )
        )}
      </nav>
    </header>
  );
}
