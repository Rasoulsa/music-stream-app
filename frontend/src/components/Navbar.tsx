/**
 * Top navigation bar — auth-aware.
 */

import { Link, NavLink } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

const linkStyle = ({ isActive }: { isActive: boolean }) => ({
  textDecoration: 'none',
  fontWeight: isActive ? 700 : 400,
  color: isActive ? '#1db954' : 'inherit',
});

export default function Navbar() {
  const { user, isAuthenticated, isLoading, logout } = useAuth();

  return (
    <header
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '1rem 1.5rem',
        borderBottom: '1px solid #eee',
      }}
    >
      <Link to='/' style={{ textDecoration: 'none' }}>
        <h1 style={{ margin: 0, fontSize: '1.25rem' }}>🎵 Music Stream App</h1>
      </Link>

      <nav style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
        <NavLink to='/' style={linkStyle} end>
          Home
        </NavLink>

        {isLoading ? null : isAuthenticated ? (
          <>
            <NavLink to='/upload' style={linkStyle}>
              Upload
            </NavLink>
            <NavLink to='/profile' style={linkStyle}>
              Profile
            </NavLink>
            <span style={{ color: '#888' }}>
              {user?.display_name || user?.username}
            </span>
            <button onClick={logout}>Log out</button>
          </>
        ) : (
          <>
            <NavLink to='/login' style={linkStyle}>
              Log in
            </NavLink>
            <NavLink to='/register' style={linkStyle}>
              Register
            </NavLink>
          </>
        )}
      </nav>
    </header>
  );
}
