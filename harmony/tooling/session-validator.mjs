/**
 * Pure-JS mirror of common/SessionValidator.ets
 *
 * Pure session validation logic.
 */

export function buildSessionState(instance, token, theme, mode) {
  const normalizedInstance = typeof instance === 'string'
    ? instance.trim().replace(/\/+$/, '').replace(/^http:\/\//i, 'https://')
    : '';
  const normalizedTheme = ['light', 'dark', 'system'].includes(theme) ? theme : 'system';
  const normalizedMode = ['online', 'offline'].includes(mode) ? mode : 'online';

  let finalInstance = normalizedInstance;
  if (finalInstance.length > 0 && !finalInstance.startsWith('http')) {
    finalInstance = `https://${finalInstance}`;
  }

  return {
    instance: finalInstance,
    token: typeof token === 'string' ? token : '',
    theme: normalizedTheme,
    mode: normalizedMode,
  };
}

export function hasServerChanged(oldInstance, newInstance) {
  const normalize = (url) => {
    if (typeof url !== 'string') return '';
    let u = url.trim().replace(/\/+$/, '');
    if (u.length > 0 && !u.startsWith('http')) u = `https://${u}`;
    return u;
  };
  return normalize(oldInstance) !== normalize(newInstance);
}

export function isNetworkError(errorMessage) {
  if (typeof errorMessage !== 'string') return false;
  return /REQUEST_|HTTP_5|timeout|network|ECONNREFUSED|EHOSTUNREACH|ENOTFOUND/i.test(errorMessage);
}

export function formatSignInError(error, isNetworkIssue) {
  const message = typeof error === 'string'
    ? error
    : error instanceof Error
      ? error.message
      : String(error);

  if (isNetworkIssue) {
    return `Sign in failed: ${message}. If the server is unreachable, tap "Use offline" to keep working on this device.`;
  }
  return `Sign in failed: ${message}`;
}

export function hasValidCredentials(username, password) {
  return typeof username === 'string' && username.trim().length > 0
    && typeof password === 'string' && password.length > 0;
}
