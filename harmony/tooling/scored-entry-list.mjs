/**
 * Pure-JS mirror of common/ScoredEntryList.ets
 *
 * Generic scored entry list with time-decay scoring.
 */

export const SCORE_HALF_LIFE_MS = 7 * 24 * 60 * 60 * 1000;

export function decayedScore(count, lastUsedAt, now) {
  if (typeof count !== 'number' || count <= 0) return 0;
  if (typeof lastUsedAt !== 'number' || typeof now !== 'number') return 0;
  const age = now - lastUsedAt;
  if (age <= 0) return count;
  const decay = Math.pow(0.5, age / SCORE_HALF_LIFE_MS);
  return count * decay;
}

export function clampNonNegative(value) {
  if (typeof value === 'number' && Number.isFinite(value) && value >= 0) return value;
  return 0;
}
