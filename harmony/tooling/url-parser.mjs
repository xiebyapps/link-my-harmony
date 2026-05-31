/**
 * Pure-JS mirror of common/UrlParser.ets
 *
 * Unified URL extraction and normalization.
 */

export const URL_PATTERN = /https?:\/\/[^\s]+/i;
export const HOST_PATTERN = /^([a-z0-9-]+\.)+[a-z]{2,}([/?#].*)?$/i;
export const URL_TRAILING_NOISE_PATTERN = /["'\]\[\)\(\}\{>,.;!?]+$/;
const HOST_FALLBACK_PATTERN = /([a-z0-9-]+\.)+[a-z]{2,}([/?#][^\s]*)?/i;

function findFirstIndex(text, candidates) {
  let best = -1;
  for (const c of candidates) {
    const idx = text.indexOf(c);
    if (idx >= 0 && (best < 0 || idx < best)) {
      best = idx;
    }
  }
  return best;
}

export function extractUrl(raw) {
  if (typeof raw !== 'string') return '';
  const value = raw.trim();
  if (value.length === 0) return '';

  const matched = value.match(URL_PATTERN);
  if (matched && matched.length > 0) {
    return matched[0].replace(URL_TRAILING_NOISE_PATTERN, '');
  }

  return '';
}

export function extractHostname(raw) {
  if (typeof raw !== 'string') return '';
  const trimmed = raw.trim();
  if (trimmed.length === 0) return '';
  const matched = trimmed.match(URL_PATTERN);
  if (!matched || !matched[0]) return '';
  const cleaned = matched[0].replace(URL_TRAILING_NOISE_PATTERN, '');
  const afterScheme = cleaned.slice(cleaned.indexOf('://') + 3);
  const endIndex = findFirstIndex(afterScheme, ['/', '?', '#']);
  const authority = endIndex >= 0 ? afterScheme.slice(0, endIndex) : afterScheme;
  const hostWithPort = authority.includes('@') ? authority.slice(authority.indexOf('@') + 1) : authority;
  const portIndex = hostWithPort.indexOf(':');
  const host = portIndex >= 0 ? hostWithPort.slice(0, portIndex) : hostWithPort;
  const lower = host.toLowerCase();
  if (lower.length === 0) return '';
  return lower.startsWith('www.') ? lower.slice(4) : lower;
}

export function normalizeUrl(raw, allowHostFallback = true) {
  if (typeof raw !== 'string') return '';
  const value = raw.trim();
  if (value.length === 0) return '';

  const matched = value.match(URL_PATTERN);
  if (matched && matched.length > 0) {
    return matched[0].replace(URL_TRAILING_NOISE_PATTERN, '');
  }

  if (allowHostFallback && HOST_PATTERN.test(value)) {
    return `https://${value}`;
  }

  return '';
}

export function extractUrlAndTitle(rawInput) {
  if (typeof rawInput !== 'string') return { url: '', title: '' };
  const value = rawInput.trim();
  if (value.length === 0) return { url: '', title: '' };

  const matchedUrl = value.match(URL_PATTERN);
  if (matchedUrl && matchedUrl.length > 0) {
    const url = matchedUrl[0].replace(URL_TRAILING_NOISE_PATTERN, '');
    const titleCandidate = value.replace(matchedUrl[0], '').trim().replace(/\s+/g, ' ');
    return {
      url,
      title: titleCandidate.length > 200 ? titleCandidate.slice(0, 200) : titleCandidate,
    };
  }

  const matchedHost = value.match(HOST_FALLBACK_PATTERN);
  if (matchedHost && matchedHost.length > 0) {
    const rawHost = matchedHost[0].replace(URL_TRAILING_NOISE_PATTERN, '');
    const titleCandidate = value.replace(matchedHost[0], '').trim().replace(/\s+/g, ' ');
    return {
      url: `https://${rawHost}`,
      title: titleCandidate.length > 200 ? titleCandidate.slice(0, 200) : titleCandidate,
    };
  }

  return { url: '', title: '' };
}
