/**
 * Application routes.
 *
 * Structure:
 *   <Layout>
 *     /                  HomePage        (public)
 *     /feed              FeedPage        (public)
 *     /users/:username   UserProfilePage (public)
 *     /login             LoginPage       (public)
 *     /register          RegisterPage    (public)
 *     <ProtectedRoute>
 *       /upload          UploadPage      (auth required)
 *       /profile         ProfilePage     (auth required)
 *     *                  NotFoundPage
 */

import { Routes, Route } from 'react-router-dom';
import { HomePage } from '../pages/HomePage';
import FeedPage from '../pages/FeedPage';
import UserProfilePage from '../pages/UserProfilePage';
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
        <Route path='/feed' element={<FeedPage />} />
        <Route path='/users/:username' element={<UserProfilePage />} />
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
