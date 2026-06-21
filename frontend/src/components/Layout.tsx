/**
 * App layout shell.
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
      <div className="min-h-screen flex flex-col">
        <Navbar />
        <main className="flex-1 max-w-5xl mx-auto w-full px-4 py-8">
          <Outlet />
        </main>
        <AudioPlayer song={activeSong} />
      </div>
    </PlayerContext.Provider>
  );
}
