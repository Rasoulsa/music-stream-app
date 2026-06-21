/**
 * App layout shell: Navbar + page content + persistent AudioPlayer.
 *
 * The AudioPlayer lives here so playback survives route changes.
 */

import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Navbar from './Navbar';
import { AudioPlayer } from './AudioPlayer';
import { PlayerContext } from '../context/PlayerContext';
import type { Song } from '../types';

export default function Layout() {
  const [activeSong, setActiveSong] = useState<Song | null>(null);

  return (
    <PlayerContext.Provider value={{ activeSong, playSong: setActiveSong }}>
      <div className='app'>
        <Navbar />
        <main style={{ padding: '1.5rem' }}>
          <Outlet />
        </main>
        <AudioPlayer song={activeSong} />
      </div>
    </PlayerContext.Provider>
  );
}
