/**
 * Formatting helpers shared across components.
 */

/** Format a duration in seconds into "m:ss" (e.g. 125 → "2:05"). */
export function formatDuration(seconds: number): string {
  if (!seconds) return '';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}
