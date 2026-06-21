/**
 * Root application component — layout shell with auth nav.
 */

import { useState } from 'react';
import { Link } from 'react-router-dom';
import { AudioPlayer } from './components/AudioPlayer';
import AppRoutes from './routes/AppRoutes';
import { useAuth } from './hooks/useAuth';
import type { Song } from './types';
import './App.css';

function App() {
  const [activeSong, setActiveSong] = useState<Song | null>(null);
  const { user, isAuthenticated, isLoading, logout } = useAuth();

  return (
    <div className='app'>
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Link to='/' style={{ textDecoration: 'none' }}>
          <h1>🎵 Music Stream App</h1>
        </Link>

        <nav>
          {isLoading ? null : isAuthenticated ? (
            <span style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
              <span>Hi, {user?.display_name || user?.username}</span>
              <button onClick={logout}>Log out</button>
            </span>
          ) : (
            <span style={{ display: 'flex', gap: '0.75rem' }}>
              <Link to='/login'>Log in</Link>
              <Link to='/register'>Register</Link>
            </span>
          )}
        </nav>
      </header>

      <AppRoutes onPlay={setActiveSong} activeSong={activeSong} />

      <AudioPlayer song={activeSong} />
    </div>
  );
}

export default App;
