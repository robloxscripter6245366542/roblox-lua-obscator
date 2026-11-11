/**
 * Work queue for handling many conversations at once.
 *
 * Two guarantees matter at volume:
 *
 *  1. Messages from the SAME chat are handled strictly in order. Two messages
 *     arriving a second apart must not run concurrently, or they interleave in
 *     the conversation history and the agent answers the wrong question.
 *
 *  2. Across DIFFERENT chats work runs in parallel, capped, so a thousand
 *     waiting customers don't open a thousand simultaneous OpenAI calls.
 */

export function createQueue({ concurrency = 8, maxDepthPerChat = 10 } = {}) {
  const chains = new Map(); // chatId -> tail promise
  const depth = new Map(); // chatId -> queued count

  let active = 0;
  const waiting = [];

  const stats = { processed: 0, dropped: 0, failed: 0 };

  function runNext() {
    if (active >= concurrency) return;
    const job = waiting.shift();
    if (!job) return;
    active++;
    job();
  }

  // Acquire a slot in the global concurrency pool.
  function acquire() {
    return new Promise((resolve) => {
      waiting.push(resolve);
      runNext();
    });
  }

  function release() {
    active--;
    runNext();
  }

  /**
   * Queue work for a chat. Returns a promise that settles when it's done.
   * Rejects immediately if that chat already has too much queued — a single
   * flooding number can't consume the whole worker pool.
   */
  function enqueue(chatId, fn) {
    const current = depth.get(chatId) || 0;
    if (current >= maxDepthPerChat) {
      stats.dropped++;
      return Promise.reject(new Error("chat_queue_full"));
    }
    depth.set(chatId, current + 1);

    const prev = chains.get(chatId) || Promise.resolve();

    // Declared up front so the cleanup below can compare against the exact
    // promise stored in `chains` — comparing against `next` would never match,
    // and the map would grow one entry per chat forever.
    let guarded;

    const next = prev.then(async () => {
      await acquire();
      try {
        const result = await fn();
        stats.processed++;
        return result;
      } catch (err) {
        stats.failed++;
        throw err;
      } finally {
        release();
        const left = (depth.get(chatId) || 1) - 1;
        if (left <= 0) {
          depth.delete(chatId);
          // Drop the chain once the chat goes idle so the map doesn't grow
          // without bound across thousands of conversations.
          if (chains.get(chatId) === guarded) chains.delete(chatId);
        } else {
          depth.set(chatId, left);
        }
      }
    });

    // The chain must not break on a failed job, or every later message from
    // that chat would be skipped.
    guarded = next.catch(() => {});
    chains.set(chatId, guarded);
    return next;
  }

  return {
    enqueue,
    stats: () => ({ ...stats, active, waiting: waiting.length, chats: chains.size }),
  };
}

/**
 * Remembers recently-seen message ids so a redelivered webhook or a
 * reconnect replay doesn't get answered twice.
 */
export function createDeduper({ ttlMs = 10 * 60 * 1000, max = 5000 } = {}) {
  const seen = new Map();

  return function isDuplicate(id) {
    if (!id) return false;
    const now = Date.now();

    if (seen.size > max) {
      for (const [key, at] of seen) {
        if (now - at > ttlMs) seen.delete(key);
        if (seen.size <= max / 2) break;
      }
    }

    const previous = seen.get(id);
    if (previous && now - previous < ttlMs) return true;
    seen.set(id, now);
    return false;
  };
}
