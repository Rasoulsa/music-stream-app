# Music Stream App — Frontend

React + TypeScript frontend for the Music Stream App, built with Vite.

## Tech Stack

- React 18 + TypeScript
- Vite
- Axios (API client)
- ESLint + Prettier

## Setup

```bash
npm install
cp .env.example .env
```

### Features
- 🔐 JWT auth (login / register / session restore)
- 🛡️ Protected routes
- 🎵 Song list with persistent global player (play / pause / next / prev / seek / volume)
- ⬆️ **Song upload** with progress bar, file validation, and cover preview
- 👤 Profile view

# Profile Feature

## Overview
View and edit the authenticated user's profile.

## Routes
- `/profile` (protected) — view + edit current user

## API
| Method | Endpoint          | Purpose             |
|--------|-------------------|---------------------|
| GET    | `/users/me/`      | Fetch current user  |
| PATCH  | `/users/me/`      | Update profile      |
| PATCH  | `/users/me/`*     | Upload avatar (multipart) |

\* Avatar uses `multipart/form-data`; text fields use JSON.

## Files
- `src/types/user.ts`
- `src/api/users.ts`
- `src/hooks/useProfile.ts`
- `src/components/profile/ProfileHeader.tsx`
- `src/components/profile/ProfileEditForm.tsx`
- `src/pages/ProfilePage.tsx`
- `src/styles/profile.css`

## Editable fields
- Display name (max 150)
- Email
- Bio (max 500, live counter)
- Avatar (image upload with preview)
