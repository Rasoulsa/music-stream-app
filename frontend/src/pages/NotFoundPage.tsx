import { Link } from 'react-router-dom';

export default function NotFoundPage() {
  return (
    <div className="min-h-[70vh] flex flex-col items-center justify-center text-center gap-4">
      <span className="text-7xl">🎵</span>
      <h2 className="text-3xl font-bold">404</h2>
      <p className="text-[var(--text-muted)]">This page doesn't exist.</p>
      <Link
        to="/"
        className="mt-2 px-5 py-2.5 rounded-lg bg-[var(--brand)] text-black font-semibold hover:bg-[var(--brand-dark)] transition-colors"
      >
        Go home
      </Link>
    </div>
  );
}
