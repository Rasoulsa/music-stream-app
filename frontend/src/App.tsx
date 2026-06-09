/**
 * Root application component.
 */

import { HealthCheck } from './components/HealthCheck';
import './App.css';

function App() {
  return (
    <div className="app">
      <header>
        <h1>🎵 Music Stream App</h1>
        <p>Full-stack demo — Django + React + TypeScript</p>
      </header>

      <main>
        <section>
          <h2>Backend Status</h2>
          <HealthCheck />
        </section>
      </main>

      <footer>
        <small>Music Stream App — portfolio project</small>
      </footer>
    </div>
  );
}

export default App;
