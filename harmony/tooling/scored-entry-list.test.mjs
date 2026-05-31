import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { decayedScore, clampNonNegative, SCORE_HALF_LIFE_MS } from './scored-entry-list.mjs';

describe('decayedScore', () => {
  it('returns count when age is zero', () => {
    assert.equal(decayedScore(5, 1000, 1000), 5);
  });

  it('returns count when age is negative (future)', () => {
    assert.equal(decayedScore(5, 1000, 500), 5);
  });

  it('returns 0 for zero count', () => {
    assert.equal(decayedScore(0, 1000, 2000), 0);
  });

  it('returns 0 for negative count', () => {
    assert.equal(decayedScore(-1, 1000, 2000), 0);
  });

  it('halves after one half-life', () => {
    const now = 1000 + SCORE_HALF_LIFE_MS;
    const score = decayedScore(10, 1000, now);
    assert.ok(Math.abs(score - 5) < 0.001);
  });

  it('quarters after two half-lives', () => {
    const now = 1000 + 2 * SCORE_HALF_LIFE_MS;
    const score = decayedScore(10, 1000, now);
    assert.ok(Math.abs(score - 2.5) < 0.001);
  });

  it('returns 0 for invalid inputs', () => {
    assert.equal(decayedScore('a', 1000, 2000), 0);
    assert.equal(decayedScore(5, 'a', 2000), 0);
    assert.equal(decayedScore(5, 1000, 'a'), 0);
  });
});

describe('clampNonNegative', () => {
  it('returns positive numbers as-is', () => {
    assert.equal(clampNonNegative(5), 5);
    assert.equal(clampNonNegative(0), 0);
  });

  it('clamps negative to 0', () => {
    assert.equal(clampNonNegative(-1), 0);
    assert.equal(clampNonNegative(-100), 0);
  });

  it('returns 0 for non-numbers', () => {
    assert.equal(clampNonNegative('a'), 0);
    assert.equal(clampNonNegative(null), 0);
    assert.equal(clampNonNegative(undefined), 0);
  });

  it('returns 0 for NaN and Infinity', () => {
    assert.equal(clampNonNegative(NaN), 0);
    assert.equal(clampNonNegative(Infinity), 0);
  });
});
