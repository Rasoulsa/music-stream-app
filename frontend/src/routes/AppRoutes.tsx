/**
 * Application routes.
 *
 * Structure:
 *   <Layout>                      ← shared shell (navbar + player)
 *     /            HomePage       (public)
 *     /login       LoginPage      (public)
 *     /register    RegisterPage   (public)
 *     <ProtectedRoute>            ← guard
 *       /upload    UploadPage     (auth)
 *       /profile   ProfilePage    (auth)
 *     *            NotFoundPage
 */

import { Routes, Route } from 'react-router-dom';
import { HomePage } from '../pages/HomePage';
import Layout from '../components/Layout';
import ProtectedRoute from '../components/ProtectedRoute';
import LoginPage from '../pages/LoginPage';
import RegisterPage from '../pages/RegisterPage';
import UploadPage from '../pages/UploadPage';
import ProfilePage from '../pages/ProfilePage';
import NotFoundPage from '../pages/NotFoundPage';

export default function AppRoutes() {
  return (
    <Routes>
      <Route element={<Layout />}>
        {/* Public */}
        <Route path='/' element={<HomePage />} />
        <Route path='/login' element={<LoginPage />} />
        <Route path='/register' element={<RegisterPage />} />

        {/* Protected */}
        <Route element={<ProtectedRoute />}>
          <Route path='/upload' element={<UploadPage />} />
          <Route path='/profile' element={<ProfilePage />} />
        </Route>

        {/* Fallback */}
        <Route path='*' element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}
