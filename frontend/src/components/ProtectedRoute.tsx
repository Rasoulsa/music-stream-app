/**
 * Route guard. Renders child routes only when authenticated.
 *
 * While auth is still loading (session restore), shows a spinner so
 * we don't flash the login page on refresh.
 *
 * Saves the attempted location so login can redirect back (Option B,
 * used here only for protected pages — Day 21 home login still goes to '/').
 */

import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import Spinner from './Spinner';

export default function ProtectedRoute() {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return <Spinner />;
  }

  if (!isAuthenticated) {
    return <Navigate to='/login' state={{ from: location }} replace />;
  }

  return <Outlet />;
}
