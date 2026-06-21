/**
 * Root component — just renders the route tree.
 * Layout, nav, and player now live inside the routes.
 */

import AppRoutes from './routes/AppRoutes';
import './App.css';

function App() {
  return <AppRoutes />;
}

export default App;
