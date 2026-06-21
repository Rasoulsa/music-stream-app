import { PlayerProvider } from './context/PlayerContext';
import AppRoutes from './routes/AppRoutes';

function App() {
  return (
    <PlayerProvider>
      <AppRoutes />
    </PlayerProvider>
  );
}

export default App;
