/**
 * Handles the upload-song mutation with progress + error state.
 */

import { useState, useCallback } from 'react';
import axios from 'axios';
import { uploadSong, type UploadSongPayload } from '../api/songs';
import type { Song } from '../types';

interface UseUploadSongResult {
  upload: (payload: UploadSongPayload) => Promise<Song | null>;
  isUploading: boolean;
  progress: number;
  fieldErrors: Record<string, string>;
  generalError: string | null;
  reset: () => void;
}

export function useUploadSong(): UseUploadSongResult {
  const [isUploading, setIsUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});
  const [generalError, setGeneralError] = useState<string | null>(null);

  const reset = useCallback(() => {
    setProgress(0);
    setFieldErrors({});
    setGeneralError(null);
  }, []);

  const upload = useCallback(
    async (payload: UploadSongPayload): Promise<Song | null> => {
      setIsUploading(true);
      reset();
      try {
        const song = await uploadSong(payload, setProgress);
        return song;
      } catch (err) {
        if (axios.isAxiosError(err) && err.response?.data) {
          const data = err.response.data as Record<string, unknown>;
          const errors: Record<string, string> = {};
          for (const [key, val] of Object.entries(data)) {
            errors[key] = Array.isArray(val) ? String(val[0]) : String(val);
          }
          if (errors.detail) {
            setGeneralError(errors.detail);
          } else {
            setFieldErrors(errors);
          }
        } else {
          setGeneralError('Upload failed. Please try again.');
        }
        return null;
      } finally {
        setIsUploading(false);
      }
    },
    [reset],
  );

  return { upload, isUploading, progress, fieldErrors, generalError, reset };
}
