type CacheEntry<T> = {
  data: T;
  expiresAt: number;
};

const store = new Map<string, CacheEntry<any>>();

const DEFAULT_TTL = 10 * 60 * 1000; // 10 min

export const cache = {
  get<T>(key: string): T | null {
    const item = store.get(key);

    if (!item) {
      return null;
    }

    if (Date.now() > item.expiresAt) {
      store.delete(key);
      return null;
    }

    return item.data as T;
  },

  set<T>(key: string, data: T, ttl = DEFAULT_TTL) {
    store.set(key, {
      data,
      expiresAt: Date.now() + ttl,
    });
  },

  clear(key: string) {
    store.delete(key);
  },

  clearAll() {
    store.clear();
  },
};