import { LRUCache } from 'lru-cache';

type Options = {
  interval: number;
  uniqueTokenPerInterval: number;
  limit: number;
};

export function rateLimit(options: Options) {
  const tokenCache = new LRUCache<string, number[]>({
    max: options.uniqueTokenPerInterval,
    ttl: options.interval,
  });

  return {
    check: (token: string): Promise<void> => {
      const tokenCount = tokenCache.get(token) || [];

      if (tokenCount.length >= options.limit) {
        return Promise.reject(new Error('Rate limit exceeded'));
      }

      // Add timestamp for current request
      tokenCount.push(Date.now());
      tokenCache.set(token, tokenCount);

      return Promise.resolve();
    },
  };
}
