# Frontend UI/UX Audit

This documents the first stage of a broader frontend audit and SoundCloud-
functional-parity roadmap. See the project journal / README roadmap for
later stages (audit compliance, feature parity, visual identity, stretch
features).

## Problems found

### Broken functionality
- **Feed and public profile song cards were read-only.** `FeedPage` and
  `UserProfilePage` rendered `<SongCard>` without an `onPlay` handler, so
  the two most-visited public pages couldn't actually play music — only
  the private "Your Library" page (via `SongList`) could. Fixed by wiring
  both pages into `usePlayer()`, using the currently-loaded song list as
  the play queue (same pattern `SongList` already used).
- **TanStack Query is installed and provided app-wide but never used.**
  `useSongs`, `FeedPage`, and `UserProfilePage` all hand-roll fetch/
  loading/error state instead. Not fixed in Stage 1 — tracked as a Stage 2
  decision (migrate onto `useQuery`, or remove the dependency).

### Code quality
- TypeScript is not running in strict mode (`tsconfig.app.json` has no
  `"strict": true`) — tracked for Stage 2.
- No accessibility linting (`eslint-plugin-jsx-a11y` not installed) —
  tracked for Stage 2.
- `AudioPlayer.tsx` had ~8 `console.log`/`console.error` calls shipping to
  production, including one firing on every song change. Removed; playback
  failure handling (`setIsPlaying(false)` fallback) is unchanged, just
  silent now. A proper in-UI error state (e.g. a toast on playback
  failure) is a reasonable follow-up, not done here.
- Dead code removed: `App.css` (170 lines, never imported),
  `assets/react.svg`, `assets/vite.svg`, `assets/hero.png` (all unused —
  confirmed via full-repo grep before deleting), and
  `components/SearchBar.tsx` was found to be unused too (`FeedPage` has
  its own inline search input) — **not removed yet**, pending a decision
  in Stage 3 on which one to keep.

### SEO / polish
- `index.html` had the literal Vite scaffold `<title>frontend</title>`,
  no meta description, no Open Graph/Twitter card tags. Fixed with a real
  title, description, and social preview tags. The `og:image` currently
  points at `favicon.svg` as a placeholder — a proper 1200×630 branded OG
  image is a good follow-up (SVGs render inconsistently in link previews
  on Discord/Slack/Twitter).

## Verification
- `npm run lint`
- `npm test` — includes 2 new regression tests (`FeedPage`,
  `UserProfilePage`) specifically covering the play-wiring bug fix
- Manually verified: clicking a card on `/feed` and on a `/users/:username`
  page now starts playback and the card shows the active/playing state

## Next stages
See the roadmap in the project README / journal for Stage 2 (TS strict
mode, a11y lint, React Query decision), Stage 3 (SearchBar decision,
`/songs/:id` pages, likes, drag-and-drop upload), Stage 4 (waveform
player, card layout, brand palette), and Stage 5 (comments, playlists,
PWA).
