/**
 * Pure session validation logic.
 *
 * Extracted from Index.ets for testability.
 * These functions validate and transform session data without side effects.
 */
import { normalizeInstanceUrl, DEFAULT_INSTANCE_URL } from './Query';
import { normalizeThemeMode, type ThemeMode, type SessionMode, type SessionState } from './SessionState';

/**
 * Build a SessionState object from individual fields.
 */
export function buildSessionState(
  instance: string,
  token: string,
  theme: ThemeMode,
  mode: SessionMode,
): SessionState {
  return {
    instance: normalizeInstanceUrl(instance),
    token,
    theme: normalizeThemeMode(theme),
    mode,
  };
}

/**
 * Determine if the server endpoint has changed.
 */
export function hasServerChanged(oldInstance: string, newInstance: string): boolean {
  return normalizeInstanceUrl(oldInstance) !== normalizeInstanceUrl(newInstance);
}

/**
 * Check if an error looks like a network issue.
 */
export function isNetworkError(errorMessage: string): boolean {
  return /REQUEST_|HTTP_5|timeout|network|ECONNREFUSED|EHOSTUNREACH|ENOTFOUND/i.test(errorMessage);
}

/**
 * Format a sign-in error message with helpful context for network errors.
 */
export function formatSignInError(error: string | Error, isNetworkIssue: boolean): string {
  const message = typeof error === 'string' ? error : error.message;

  if (isNetworkIssue) {
    return `Sign in failed: ${message}. If the server is unreachable, tap "Use offline" to keep working on this device.`;
  }
  return `Sign in failed: ${message}`;
}

/**
 * Validate that credentials are non-empty.
 */
export function hasValidCredentials(username: string, password: string): boolean {
  return username.trim().length > 0 && password.length > 0;
}
