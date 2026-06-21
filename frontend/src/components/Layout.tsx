/**
 * App layout shell.
 *
 * The persistent AudioPlayer lives here so it survives route changes.
 * Player state comes from PlayerProvider (mounted in App.tsx), so this
 * component no longer manages its own context.
 */

import { Outlet } from 'react-router-dom';
import Navbar from './Navbar';
import { AudioPlayer } from './AudioPlayer';

export default function Layout() {
  return (
    <div className="min-h-screen flex flex-col">
      <Navbar />
      <main className="flex-1 max-w-5xl mx-auto w-full px-4 py-8 pb-28">
        <Outlet />
      </main>

      {/* Persistent global player — reads state from PlayerContext */}
      <AudioPlayer />
    </div>
  );
}
