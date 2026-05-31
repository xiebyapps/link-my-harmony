import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  buildSessionState,
  hasServerChanged,
  isNetworkError,
  formatSignInError,
  hasValidCredentials,
} from './session-validator.mjs';

describe('buildSessionState', () => {
  it('normalizes instance URL', () => {
    const state = buildSessionState('example.com', 'tok', 'system', 'online');
    assert.equal(state.instance, 'https://example.com');
  });

  it('strips trailing slash', () => {
    const state = buildSessionState('https://example.com/', 'tok', 'system', 'online');
    assert.equal(state.instance, 'https://example.com');
  });

  it('defaults invalid theme to system', () => {
    const state = buildSessionState('https://x.com', '', 'invalid', 'online');
    assert.equal(state.theme, 'system');
  });

  it('defaults invalid mode to online', () => {
    const state = buildSessionState('https://x.com', '', 'light', 'invalid');
    assert.equal(state.mode, 'online');
  });

  it('preserves valid values', () => {
    const state = buildSessionState('https://x.com', 'mytoken', 'dark', 'offline');
    assert.equal(state.token, 'mytoken');
    assert.equal(state.theme, 'dark');
    assert.equal(state.mode, 'offline');
  });
});

describe('hasServerChanged', () => {
  it('returns false for same URL', () => {
    assert.equal(hasServerChanged('https://a.com', 'https://a.com'), false);
  });

  it('returns true for different URL', () => {
    assert.equal(hasServerChanged('https://a.com', 'https://b.com'), true);
  });

  it('normalizes before comparing', () => {
    assert.equal(hasServerChanged('a.com/', 'https://a.com'), false);
  });
});

describe('isNetworkError', () => {
  it('detects REQUEST_ errors', () => {
    assert.equal(isNetworkError('REQUEST_TIMEOUT'), true);
  });

  it('detects HTTP_5 errors', () => {
    assert.equal(isNetworkError('HTTP_503'), true);
  });

  it('detects timeout', () => {
    assert.equal(isNetworkError('connection timeout'), true);
  });

  it('detects ECONNREFUSED', () => {
    assert.equal(isNetworkError('ECONNREFUSED'), true);
  });

  it('returns false for non-network errors', () => {
    assert.equal(isNetworkError('Invalid credentials'), false);
  });

  it('returns false for non-string', () => {
    assert.equal(isNetworkError(null), false);
    assert.equal(isNetworkError(42), false);
  });
});

describe('formatSignInError', () => {
  it('formats string error', () => {
    assert.equal(formatSignInError('bad creds', false), 'Sign in failed: bad creds');
  });

  it('formats Error object', () => {
    const result = formatSignInError(new Error('bad creds'), false);
    assert.equal(result, 'Sign in failed: bad creds');
  });

  it('adds network hint for network errors', () => {
    const result = formatSignInError('timeout', true);
    assert.ok(result.includes('Use offline'));
  });

  it('does not add hint for non-network errors', () => {
    const result = formatSignInError('bad creds', false);
    assert.ok(!result.includes('Use offline'));
  });
});

describe('hasValidCredentials', () => {
  it('returns true for valid credentials', () => {
    assert.equal(hasValidCredentials('user', 'pass'), true);
  });

  it('returns false for empty username', () => {
    assert.equal(hasValidCredentials('', 'pass'), false);
  });

  it('returns false for whitespace-only username', () => {
    assert.equal(hasValidCredentials('   ', 'pass'), false);
  });

  it('returns false for empty password', () => {
    assert.equal(hasValidCredentials('user', ''), false);
  });

  it('returns false for non-string inputs', () => {
    assert.equal(hasValidCredentials(null, 'pass'), false);
    assert.equal(hasValidCredentials('user', null), false);
  });
});
