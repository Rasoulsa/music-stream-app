# Frontend — Music Stream App

React + TypeScript frontend for the Music Stream App, built with Vite.

The frontend provides the user interface for authentication, browsing songs,
uploading songs, playing audio, viewing profiles, and visiting public user
pages.

For the full system architecture, see:

👉 [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)

---

## Tech Stack

| Area | Technology |
|---|---|
| Framework | React |
| Language | TypeScript |
| Build tool | Vite |
| Routing | React Router |
| API client | Axios |
| Server state | TanStack Query |
| Styling | CSS / Tailwind CSS |
| Authentication | JWT access/refresh tokens |
| Testing | Vitest, React Testing Library |
| Linting | ESLint |
| Formatting | Prettier |
| Containerization | Docker |

---

## Frontend Features

- User registration
- User login
- JWT token storage and session restore
- Protected routes
- Song list page
- Public feed page
- Song search/filtering
- Audio player
- Play / pause support
- Upload song form
- Upload progress handling
- File validation
- Current user profile page
- Public user profile pages
- API health check component
- Error/loading states
- Frontend tests with Vitest and React Testing Library

---

## Frontend Structure

```text
frontend/
├── public/
│   ├── favicon.svg
│   └── icons.svg
├── src/
│   ├── api/
│   │   ├── auth.ts
│   │   ├── client.ts
│   │   ├── health.ts
│   │   ├── songs.ts
│   │   └── users.ts
│   ├── components/
│   │   ├── AudioPlayer.tsx
│   │   ├── HealthCheck.tsx
│   │   ├── Layout.tsx
│   │   ├── Navbar.tsx
│   │   ├── ProtectedRoute.tsx
│   │   ├── SearchBar.tsx
│   │   ├── SongCard.tsx
│   │   ├── SongList.tsx
│   │   └── Spinner.tsx
│   ├── context/
│   │   ├── AuthContext.tsx
│   │   └── PlayerContext.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   ├── usePlayer.ts
│   │   ├── useSongs.ts
│   │   └── useUploadSong.ts
│   ├── pages/
│   │   ├── FeedPage.tsx
│   │   ├── HomePage.tsx
│   │   ├── LoginPage.tsx
│   │   ├── NotFoundPage.tsx
│   │   ├── ProfilePage.tsx
│   │   ├── RegisterPage.tsx
│   │   ├── UploadPage.tsx
│   │   └── UserProfilePage.tsx
│   ├── routes/
│   │   └── AppRoutes.tsx
│   ├── test/
│   │   └── setup.ts
│   ├── types/
│   │   ├── index.ts
│   │   └── player.ts
│   ├── utils/
│   │   ├── fileValidation.ts
│   │   ├── format.ts
│   │   └── token.ts
│   ├── App.tsx
│   ├── App.css
│   ├── index.css
│   └── main.tsx
├── Dockerfile
├── nginx.conf
├── package.json
├── vite.config.ts
├── vitest.config.ts
└── README.md
```

---

## Environment Variables

If you run the frontend locally with `npm run dev`, create a frontend
environment file:

```bash
cd frontend
cp .env.example .env
```

The frontend uses environment variables for API configuration.

Example:

```env
VITE_API_BASE_URL=http://localhost:8000
```

If you run the full app with Docker Compose from the project root, the
development stack mainly uses the root `.env.dev` file:

```bash
cp .env.dev.example .env.dev
```

For production-like Docker runs, the stack uses:

```bash
cp .env.prod.example .env.prod
```

---

## Running with Docker

From the project root:

```bash
make dev-up-d
```

View frontend logs:

```bash
make dev-logs-frontend
```

Open a shell inside the frontend container:

```bash
make dev-shell-frontend
```

Stop the development stack:

```bash
make dev-down
```

---

## Running Locally Without Docker

From the frontend directory:

```bash
cd frontend
npm install
npm run dev
```

The Vite dev server usually runs at:

```text
http://localhost:3000
```

If another port is configured or already in use, Vite will show the correct URL
in the terminal.

---

## Common Scripts

Run these from the `frontend/` directory.

### Start development server

```bash
npm run dev
```

### Build production assets

```bash
npm run build
```

### Preview production build

```bash
npm run preview
```

### Run tests

```bash
npm test
```

### Run linting

```bash
npm run lint
```

---

## API Integration

The frontend talks to the backend API through Axios.

Important API files:

| File | Purpose |
|---|---|
| `src/api/client.ts` | Shared Axios client |
| `src/api/auth.ts` | Login/register/auth API calls |
| `src/api/songs.ts` | Song list, upload, retrieve APIs |
| `src/api/users.ts` | Profile and public user APIs |
| `src/api/health.ts` | Backend health check API |

The backend API is versioned under:

```text
/api/v1/
```

Important backend routes used by the frontend:

| Endpoint | Purpose |
|---|---|
| `/api/v1/auth/register/` | Register user |
| `/api/v1/auth/login/` | Login user |
| `/api/v1/auth/refresh/` | Refresh JWT token |
| `/api/v1/songs/` | List/upload songs |
| `/api/v1/songs/mine/` | Current user's songs |
| `/api/v1/feed/` | Public feed |
| `/api/v1/users/me/` | Current user's profile |
| `/api/v1/users/<username>/` | Public profile |
| `/api/v1/users/<username>/songs/` | Public user songs |

---

## Authentication Flow

The frontend authentication flow:

```text
User submits login form
  → frontend sends POST /api/v1/auth/login/
  → backend returns access + refresh tokens
  → frontend stores tokens
  → Axios attaches Authorization header
  → protected routes become accessible
```

Authenticated requests use:

```http
Authorization: Bearer <access-token>
```

Relevant files:

| File | Purpose |
|---|---|
| `src/context/AuthContext.tsx` | Auth state and actions |
| `src/hooks/useAuth.ts` | Auth hook |
| `src/utils/token.ts` | Token helpers |
| `src/api/auth.ts` | Auth API calls |
| `src/components/ProtectedRoute.tsx` | Route protection |

---

## Audio Player

The app includes a global audio player.

Relevant files:

| File | Purpose |
|---|---|
| `src/components/AudioPlayer.tsx` | Player UI |
| `src/context/PlayerContext.tsx` | Global player state |
| `src/hooks/usePlayer.ts` | Player hook |
| `src/types/player.ts` | Player-related TypeScript types |

The backend and Nginx support HTTP Range requests so browser seeking works for
uploaded audio files.

---

## Song Upload

Song upload is handled from the frontend using multipart form data.

Relevant files:

| File | Purpose |
|---|---|
| `src/pages/UploadPage.tsx` | Upload page |
| `src/hooks/useUploadSong.ts` | Upload logic |
| `src/utils/fileValidation.ts` | File validation |
| `src/api/songs.ts` | Upload API call |

Upload flow:

```text
User selects audio file
  → frontend validates file
  → frontend sends multipart POST /api/v1/songs/
  → backend stores file in MinIO/S3
  → backend creates song row
  → Celery extracts metadata
```

---

## Pages and Routes

Main page components:

| Page | Purpose |
|---|---|
| `HomePage.tsx` | Landing/home page |
| `LoginPage.tsx` | Login form |
| `RegisterPage.tsx` | Registration form |
| `FeedPage.tsx` | Public feed |
| `UploadPage.tsx` | Upload song |
| `ProfilePage.tsx` | Current user profile |
| `UserProfilePage.tsx` | Public user profile |
| `NotFoundPage.tsx` | 404 page |

Routes are managed in:

```text
src/routes/AppRoutes.tsx
```

---

## Testing

Frontend tests use:

- Vitest
- React Testing Library
- jest-dom matchers
- jsdom test environment

Run tests:

```bash
npm test
```

Important test files:

```text
src/api/songs.test.ts
src/components/SongCard.test.tsx
src/pages/FeedPage.test.tsx
src/utils/format.test.ts
```

Test setup file:

```text
src/test/setup.ts
```

---

## Docker Production Build

The frontend has its own Dockerfile:

```text
frontend/Dockerfile
```

In the production-like stack:

- Vite builds static frontend assets
- Nginx serves the built frontend
- Root Nginx routes browser requests to the frontend container

From the project root:

```bash
make prod-up
```

View frontend production logs:

```bash
make prod-logs-frontend
```

---

## Styling

Main style files:

```text
src/index.css
src/App.css
```

The project also includes Tailwind-related dependencies.

---

## Troubleshooting

### Frontend cannot reach backend

Check the frontend env file:

```text
frontend/.env
```

Check the API base URL.

Then verify backend health:

```bash
curl http://localhost:8000/api/health/
```

If using Docker, check logs:

```bash
make dev-logs-frontend
make dev-logs-backend
```

---

### Login works but protected pages redirect

Possible causes:

- access token not stored correctly
- token expired and refresh failed
- Authorization header not attached by Axios
- backend returned 401

Check:

```text
src/context/AuthContext.tsx
src/utils/token.ts
src/api/client.ts
```

---

### Audio does not play

Check:

- uploaded song has a valid `audio_file` URL
- Nginx can proxy media requests
- object storage is reachable
- browser network tab returns `200` or `206`

Production smoke test checks streaming and Range requests:

```bash
make smoke-prod
```

---

### Tests fail because DOM matchers are missing

Check that this file exists:

```text
src/test/setup.ts
```

And that `vitest.config.ts` uses it as setup.

---

## Related Documentation

- [`../README.md`](../README.md)
- [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)
- [`../docs/env-management.md`](../docs/env-management.md)
- [`../docs/security.md`](../docs/security.md)
- [`../docs/performance.md`](../docs/performance.md)
- [`../docs/smoke-tests.md`](../docs/smoke-tests.md)
- [`../backend/README.md`](../backend/README.md)
