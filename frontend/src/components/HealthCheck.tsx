/**
 * Displays the backend health status to prove the
 * frontend can talk to the API.
 */

import { useEffect, useState } from 'react';
import { getHealth } from '../api/health';
import type { HealthResponse } from '../types';

type Status = 'loading' | 'success' | 'error';

export function HealthCheck() {
  const [status, setStatus] = useState<Status>('loading');
  const [data, setData] = useState<HealthResponse | null>(null);

  useEffect(() => {
    getHealth()
      .then((result) => {
        setData(result);
        setStatus('success');
      })
      .catch(() => {
        setStatus('error');
      });
  }, []);

  if (status === 'loading') {
    return <p>Checking backend connection...</p>;
  }

  if (status === 'error') {
    return (
      <p style={{ color: 'red' }}>
        ❌ Could not reach the backend. Is the Django server running?
      </p>
    );
  }

  return (
    <p style={{ color: 'green' }}>
      ✅ Backend connected — status: <strong>{data?.status}</strong>, service:{' '}
      <strong>{data?.service}</strong>
    </p>
  );
}
