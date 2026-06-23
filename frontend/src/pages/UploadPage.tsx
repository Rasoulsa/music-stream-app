import { useState, useRef, type FormEvent, type ChangeEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUploadSong } from '../hooks/useUploadSong';
import { validateAudio, validateImage, formatBytes } from '../utils/fileValidation';

export default function UploadPage() {
  const navigate = useNavigate();
  const { upload, isUploading, progress, fieldErrors, generalError } = useUploadSong();

  const [title, setTitle] = useState('');
  const [artist, setArtist] = useState('');
  const [album, setAlbum] = useState('');
  const [isPublic, setIsPublic] = useState(true);

  const [audioFile, setAudioFile] = useState<File | null>(null);
  const [coverImage, setCoverImage] = useState<File | null>(null);
  const [coverPreview, setCoverPreview] = useState<string | null>(null);

  const [localError, setLocalError] = useState<string | null>(null);
  const audioInputRef = useRef<HTMLInputElement>(null);

  const handleAudioChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const err = validateAudio(file);
    if (err) {
      setLocalError(err);
      setAudioFile(null);
      return;
    }
    setLocalError(null);
    setAudioFile(file);
    if (!title) setTitle(file.name.replace(/\.[^/.]+$/, ''));
  };

  const handleCoverChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const err = validateImage(file);
    if (err) {
      setLocalError(err);
      return;
    }
    setLocalError(null);
    setCoverImage(file);
    setCoverPreview(URL.createObjectURL(file));
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setLocalError(null);

    if (!audioFile) {
      setLocalError('Please select an audio file.');
      return;
    }

    if (!title.trim()) {
      setLocalError('Title is required.');
      return;
    }

    if (!artist.trim()) {
      setLocalError('Artist name is required.');
      return;
    }

    const song = await upload({
      title: title.trim(),
      artist: artist.trim(),
      album: album.trim() || undefined,
      audio_file: audioFile,
      cover_image: coverImage,
      is_public: isPublic,
    });

    if (song) {
      navigate('/');
    }
  };

  return (
    <div className="max-w-xl mx-auto">
      <div className="mb-8">
        <h2 className="text-2xl font-bold">Upload a song</h2>
        <p className="text-[var(--text-muted)] text-sm mt-1">
          Share your music with the community
        </p>
      </div>

      <form
        onSubmit={handleSubmit}
        className="bg-[var(--surface-2)] border border-[var(--border)] rounded-2xl p-6 flex flex-col gap-5"
      >
        {/* Audio dropzone */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Audio file <span className="text-[var(--brand)]">*</span>
          </label>
          <button
            type="button"
            onClick={() => audioInputRef.current?.click()}
            className={`w-full flex items-center justify-center h-28 rounded-xl border-2 border-dashed transition-colors ${
              audioFile
                ? 'border-[var(--brand)] bg-[var(--brand)]/5'
                : 'border-[var(--border)] hover:border-[var(--surface-3)]'
            }`}
          >
            {audioFile ? (
              <div className="text-center">
                <p className="text-2xl mb-1">🎵</p>
                <p className="text-sm font-medium truncate max-w-xs">
                  {audioFile.name}
                </p>
                <p className="text-xs text-[var(--text-muted)]">
                  {formatBytes(audioFile.size)} — click to change
                </p>
              </div>
            ) : (
              <div className="text-center text-[var(--text-muted)]">
                <p className="text-2xl mb-1">⬆️</p>
                <p className="text-sm">Click to choose an audio file</p>
                <p className="text-xs">MP3, WAV, FLAC, OGG, M4A (max 50 MB)</p>
              </div>
            )}
          </button>
          <input
            ref={audioInputRef}
            type="file"
            accept="audio/*"
            onChange={handleAudioChange}
            className="hidden"
          />
          {fieldErrors.audio_file && (
            <p className="text-xs text-[var(--danger)] mt-1">
              {fieldErrors.audio_file}
            </p>
          )}
        </div>

        {/* Title */}
        <label>
          Title <span className="text-[var(--brand)]">*</span>
          <input
            value={title}
            onChange={(e) => {
              setTitle(e.target.value);
              if (localError === 'Title is required.') setLocalError(null);
            }}
            placeholder="Song title"
          />
          {fieldErrors.title && (
            <p className="text-xs text-[var(--danger)] mt-1">{fieldErrors.title}</p>
          )}
        </label>

        {/* Artist + Album */}
        <div className="grid grid-cols-2 gap-4">
          <label>
            Artist <span className="text-[var(--brand)]">*</span>
            <input
              value={artist}
              onChange={(e) => {
                setArtist(e.target.value);
                if (localError === 'Artist name is required.') setLocalError(null);
              }}
              placeholder="Artist name"
            />
            {fieldErrors.artist && (
              <p className="text-xs text-[var(--danger)] mt-1">{fieldErrors.artist}</p>
            )}
          </label>
          <label>
            Album
            <input
              value={album}
              onChange={(e) => setAlbum(e.target.value)}
              placeholder="Album name"
            />
          </label>
        </div>

        {/* Cover image */}
        <div>
          <label className="block text-sm font-medium mb-2">
            Cover image (optional)
          </label>
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-lg bg-[var(--surface-3)] overflow-hidden flex items-center justify-center text-2xl flex-shrink-0">
              {coverPreview ? (
                <img
                  src={coverPreview}
                  alt="cover preview"
                  className="w-full h-full object-cover"
                />
              ) : (
                <span>🖼️</span>
              )}
            </div>
            <label className="text-sm text-[var(--brand)] cursor-pointer">
              Choose image
              <input
                type="file"
                accept="image/*"
                onChange={handleCoverChange}
                className="hidden"
              />
            </label>
          </div>
          {fieldErrors.cover_image && (
            <p className="text-xs text-[var(--danger)] mt-1">
              {fieldErrors.cover_image}
            </p>
          )}
        </div>

        {/* Public toggle */}
        <label className="flex items-center gap-3 cursor-pointer">
          <input
            type="checkbox"
            checked={isPublic}
            onChange={(e) => setIsPublic(e.target.checked)}
            className="w-4 h-4 accent-[var(--brand)]"
          />
          <span className="text-sm">
            Make this song public
            <span className="block text-xs text-[var(--text-muted)]">
              Public songs appear in the feed for everyone.
            </span>
          </span>
        </label>

        {/* Errors */}
        {(localError || generalError) && (
          <p className="text-sm text-[var(--danger)] bg-[var(--danger)]/10 px-3 py-2 rounded-lg">
            {localError || generalError}
          </p>
        )}

        {/* Progress */}
        {isUploading && (
          <div>
            <div className="flex justify-between text-xs text-[var(--text-muted)] mb-1">
              <span>Uploading…</span>
              <span>{progress}%</span>
            </div>
            <div className="h-2 rounded-full bg-[var(--surface-3)] overflow-hidden">
              <div
                className="h-full bg-[var(--brand)] transition-all"
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        )}

        <button
          type="submit"
          disabled={isUploading || !audioFile}
          className="w-full py-2.5 rounded-lg bg-[var(--brand)] hover:bg-[var(--brand-dark)] text-black font-bold transition-colors disabled:opacity-50"
        >
          {isUploading ? 'Uploading…' : 'Upload song'}
        </button>
      </form>
    </div>
  );
}
