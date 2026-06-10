/**
 * Root application component.
 */

import { useState } from 'react';
import { AudioPlayer } from './components/AudioPlayer';
import { HealthCheck } from './components/HealthCheck';
import { SongList } from './components/SongList';
import type { Song } from './types';
import './App.css';

function App() {
  const [activeSong, setActiveSong] = useState<Song | null>(null);

  return (
    <div className="app">
      <header>
        <h1>🎵 Music Stream App</h1>
        {/* <p>Full-stack demo — Django + React + TypeScript</p> */}
        <HealthCheck />
      </header>

      <main>
        <SongList activeSong={activeSong} onPlay={setActiveSong} />
      </main>

      <AudioPlayer song={activeSong} />
    </div>
  );
}

export default App;
