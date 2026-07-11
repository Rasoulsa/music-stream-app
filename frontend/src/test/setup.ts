/**
 * Global test setup — runs before every test file.
 * Like conftest.py in pytest.
 */

import '@testing-library/jest-dom';
import { afterEach, vi } from 'vitest';
import { cleanup } from '@testing-library/react';

// jsdom does not implement HTMLMediaElement playback (play/pause/load
// are stubs that return undefined, not a Promise). AudioPlayer.tsx calls
// audio.play().catch(...), which throws a TypeError under real jsdom
// behavior. Mocking these once here means every test that renders
// AudioPlayer (now, and in future stages) works without repeating this
// per test file.
Object.defineProperty(window.HTMLMediaElement.prototype, 'play', {
  configurable: true,
  value: vi.fn().mockResolvedValue(undefined),
});
Object.defineProperty(window.HTMLMediaElement.prototype, 'pause', {
  configurable: true,
  value: vi.fn(),
});
Object.defineProperty(window.HTMLMediaElement.prototype, 'load', {
  configurable: true,
  value: vi.fn(),
});

// Unmount React tree + reset mocks after each test (test isolation).
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});
