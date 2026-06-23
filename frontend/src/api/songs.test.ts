import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getFeed } from './songs';
import { apiClient } from './client';

// Mock the axios client — tests never hit the real backend.
vi.mock('./client', () => ({
  apiClient: { get: vi.fn(), post: vi.fn() },
}));

const mockGet = vi.mocked(apiClient.get);

describe('songs API', () => {
  beforeEach(() => vi.clearAllMocks());

  it('getFeed calls /feed/ with search + ordering params', async () => {
    mockGet.mockResolvedValue({
      data: { count: 0, next: null, previous: null, results: [] },
    });

    await getFeed({ search: 'jazz', ordering: '-created_at' });

    expect(mockGet).toHaveBeenCalledWith('/feed/', {
      params: { search: 'jazz', ordering: '-created_at' },
    });
  });

  it('getFeed returns the paginated payload', async () => {
    const payload = {
      count: 1,
      next: null,
      previous: null,
      results: [{ id: 1, title: 'Song A' }],
    };
    mockGet.mockResolvedValue({ data: payload });

    const result = await getFeed();

    expect(result).toEqual(payload);
    expect(result.results).toHaveLength(1);
  });
});
