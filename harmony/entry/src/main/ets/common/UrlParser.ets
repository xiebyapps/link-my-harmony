/**
 * Unified URL extraction and normalization.
 *
 * This is the single source of truth for URL regex patterns.
 * Previously duplicated across HostCollectionMemory.ets, ShareIntent.ets,
 * and Index.ets with inconsistent behavior.
 */

export const URL_PATTERN: RegExp = /https?:\/\/[^\s]+/i;
export const HOST_PATTERN: RegExp = /^([a-z0-9-]+\.)+[a-z]{2,}([/?#].*)?$/i;
export const URL_TRAILING_NOISE_PATTERN: RegExp = /["'\]\[\)\(\}\{>,.;!?]+$/;
const HOST_FALLBACK_PATTERN: RegExp = /([a-z0-9-]+\.)+[a-z]{2,}([/?#][^\s]*)?/i;

export interface ParsedLinkInput {
  url: string;
  title: string;
}

/**
 * Extract the first URL from a raw string, stripping trailing punctuation.
 * Returns the cleaned URL or empty string if none found.
 */
export function extractUrl(raw: string): string {
  const value = raw.trim();
  if (value.length === 0) {
    return '';
  }

  const matched = value.match(URL_PATTERN);
  if (matched && matched.length > 0) {
    return matched[0].replace(URL_TRAILING_NOISE_PATTERN, '');
  }

  return '';
}

/**
 * Extract a hostname from a raw URL string.
 * Strips scheme, port, auth, www prefix. Returns lowercase host.
 */
export function extractHostname(raw: string): string {
  const trimmed: string = raw.trim();
  if (trimmed.length === 0) {
    return '';
  }
  const matched = trimmed.match(URL_PATTERN);
  if (matched === null || matched.length === 0) {
    return '';
  }
  const cleaned: string = matched[0].replace(URL_TRAILING_NOISE_PATTERN, '');
  const schemeIndex: number = cleaned.indexOf('://');
  if (schemeIndex < 0) {
    return '';
  }
  const afterScheme: string = cleaned.slice(schemeIndex + 3);
  const endIndex: number = findFirstIndex(afterScheme, ['/', '?', '#']);
  const authority: string = endIndex >= 0 ? afterScheme.slice(0, endIndex) : afterScheme;
  const atIndex: number = authority.indexOf('@');
  const hostWithPort: string = atIndex >= 0 ? authority.slice(atIndex + 1) : authority;
  const portIndex: number = hostWithPort.indexOf(':');
  const host: string = portIndex >= 0 ? hostWithPort.slice(0, portIndex) : hostWithPort;
  const lower: string = host.toLowerCase();
  if (lower.length === 0) {
    return '';
  }
  return lower.startsWith('www.') ? lower.slice(4) : lower;
}

/**
 * Normalize a raw URL string: trim, match URL_PATTERN, strip trailing noise.
 * Optionally fall back to treating bare hostnames as https:// URLs.
 */
export function normalizeUrl(raw: string, allowHostFallback: boolean = true): string {
  const value = raw.trim();
  if (value.length === 0) {
    return '';
  }

  const matched = value.match(URL_PATTERN);
  if (matched && matched.length > 0) {
    return matched[0].replace(URL_TRAILING_NOISE_PATTERN, '');
  }

  if (allowHostFallback && HOST_PATTERN.test(value)) {
    return `https://${value}`;
  }

  return '';
}

/**
 * Extract URL and title from a user-typed input string.
 * Handles "https://example.com Some Title" and bare hostnames.
 */
export function extractUrlAndTitle(rawInput: string): ParsedLinkInput {
  const value = rawInput.trim();
  if (value.length === 0) {
    return { url: '', title: '' };
  }

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

function findFirstIndex(text: string, candidates: Array<string>): number {
  let best: number = -1;
  for (let i: number = 0; i < candidates.length; i++) {
    const idx: number = text.indexOf(candidates[i]);
    if (idx >= 0 && (best < 0 || idx < best)) {
      best = idx;
    }
  }
  return best;
}
