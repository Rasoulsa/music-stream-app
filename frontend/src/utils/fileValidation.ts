/**
 * Client-side file validation for uploads.
 */

const MAX_AUDIO_MB = 50;
const MAX_IMAGE_MB = 5;

const AUDIO_TYPES = ['audio/mpeg', 'audio/wav', 'audio/flac', 'audio/ogg', 'audio/mp4'];
const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

export function validateAudio(file: File): string | null {
  if (!AUDIO_TYPES.includes(file.type)) {
    return 'Unsupported audio format (use MP3, WAV, FLAC, OGG, or M4A).';
  }
  if (file.size > MAX_AUDIO_MB * 1024 * 1024) {
    return `Audio file too large (max ${MAX_AUDIO_MB} MB).`;
  }
  return null;
}

export function validateImage(file: File): string | null {
  if (!IMAGE_TYPES.includes(file.type)) {
    return 'Unsupported image format (use JPG, PNG, or WebP).';
  }
  if (file.size > MAX_IMAGE_MB * 1024 * 1024) {
    return `Image too large (max ${MAX_IMAGE_MB} MB).`;
  }
  return null;
}

export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}
