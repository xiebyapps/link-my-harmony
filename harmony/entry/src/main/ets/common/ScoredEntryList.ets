/**
 * Generic scored entry list with time-decay scoring.
 *
 * Unifies the identical patterns in CollectionUsage.ets and HostCollectionMemory.ets.
 * Both modules used the same half-life decay algorithm with different key shapes.
 */

export const SCORE_HALF_LIFE_MS: number = 7 * 24 * 60 * 60 * 1000;

/**
 * Calculate the time-decay score for an entry.
 * @param count The entry's count/frequency
 * @param lastUsedAt Timestamp of last use (ms since epoch)
 * @param now Current timestamp (ms since epoch)
 * @returns Decayed score
 */
export function decayedScore(count: number, lastUsedAt: number, now: number): number {
  if (count <= 0) {
    return 0;
  }
  const age: number = now - lastUsedAt;
  if (age <= 0) {
    return count;
  }
  const decay: number = Math.pow(0.5, age / SCORE_HALF_LIFE_MS);
  return count * decay;
}

/**
 * Clamp a non-negative number, defaulting to 0 for invalid inputs.
 */
export function clampNonNegative(value: number): number {
  if (Number.isFinite(value) && value >= 0) {
    return value;
  }
  return 0;
}
