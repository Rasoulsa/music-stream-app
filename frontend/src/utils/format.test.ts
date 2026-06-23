import { describe, it, expect } from 'vitest';
import { formatDuration } from './format';

describe('formatDuration', () => {
  it('formats seconds into m:ss', () => {
    expect(formatDuration(125)).toBe('2:05');
  });

  it('pads single-digit seconds', () => {
    expect(formatDuration(61)).toBe('1:01');
  });

  it('returns empty string for 0 / falsy', () => {
    expect(formatDuration(0)).toBe('');
  });

  it('handles exactly one minute', () => {
    expect(formatDuration(60)).toBe('1:00');
  });

  it('handles long durations (over 10 min)', () => {
    expect(formatDuration(625)).toBe('10:25');
  });
});
