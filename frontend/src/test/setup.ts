/**
 * Global test setup — runs before every test file.
 * Like conftest.py in pytest.
 */

import '@testing-library/jest-dom';
import { afterEach, vi } from 'vitest';
import { cleanup } from '@testing-library/react';

// Unmount React tree + reset mocks after each test (test isolation).
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});
