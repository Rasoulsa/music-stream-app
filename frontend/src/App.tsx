/**
 * Root application component — layout shell.
 */

import { useState } from 'react';
import { AudioPlayer } from './components/AudioPlayer';
import AppRoutes from './routes/AppRoutes';
import type { Song } from './types';
import './App.css';

function App() {
  const [activeSong, setActiveSong] = useState<Song | null>(null);

  return (
    <div className='app'>
      <header>
        <h1>🎵 Music Stream App</h1>
      </header>

      <AppRoutes onPlay={setActiveSong} activeSong={activeSong} />

      <AudioPlayer song={activeSong} />
    </div>
  );
}

export default App;
