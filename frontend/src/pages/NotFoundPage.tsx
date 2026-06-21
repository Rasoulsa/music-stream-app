/**
 * 404 fallback.
 */

import { Link } from 'react-router-dom';

export default function NotFoundPage() {
  return (
    <section style={{ textAlign: 'center', padding: '3rem' }}>
      <h2>404 — Page not found</h2>
      <p>
        <Link to='/'>Go home</Link>
      </p>
    </section>
  );
}
