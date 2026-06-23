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

## Frontend Pages

| Route | Page | Auth | Backend endpoint |
|-------|------|------|------------------|
| `/` | Home | public | `/songs/` |
| `/feed` | Discover | public | `/feed/` |
| `/users/:username` | User Profile | public | `/users/:username/`, `/users/:username/songs/` |
| `/login` | Login | public | `/auth/login/` |
| `/register` | Register | public | `/auth/register/` |
| `/upload` | Upload | **protected** | `POST /songs/` |
| `/profile` | My Profile | **protected** | `/users/me/` |

The feed and user profiles are fully public — no login required.
Song cards link to the uploader's profile.

## Frontend Testing

The frontend uses **Vitest** + **React Testing Library**, following the
same testing philosophy as the backend (Arrange → Act → Assert, mock the
boundary, test behavior not implementation).

### Stack
| Tool | Role |
|------|------|
| Vitest | Test runner |
| @testing-library/react | Render components, query the DOM |
| @testing-library/user-event | Simulate real user interactions |
| @testing-library/jest-dom | DOM-specific matchers |
| jsdom | Headless browser environment |

### Running tests

```bash
cd frontend

npm test              # run once (CI mode)
npm run test:watch    # watch mode (re-run on change)
npm run test:ui       # browser UI
npm run test:coverage # coverage report
```
