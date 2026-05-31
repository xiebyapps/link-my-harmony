import { URL_PATTERN, HOST_PATTERN, URL_TRAILING_NOISE_PATTERN, normalizeUrl } from './url-parser.mjs';

function normalizeSharedUrl(raw, allowHostFallback = true) {
  return normalizeUrl(raw, allowHostFallback);
}

function readStringValue(value) {
  if (typeof value === 'string') return value;
  if (Array.isArray(value) && value.length > 0 && typeof value[0] === 'string') {
    return value[0];
  }

  return '';
}

function extractUrlFromUnknownValue(value, allowHostFallback = false) {
  const direct = normalizeSharedUrl(readStringValue(value), allowHostFallback);
  if (direct) return direct;
  if (value === undefined || value === null) return '';

  if (Array.isArray(value)) {
    for (const item of value) {
      const nested = extractUrlFromUnknownValue(item, false);
      if (nested) return nested;
    }
    return '';
  }

  if (typeof value === 'object') {
    const preferredKeys = ['uri', 'url', 'link', '2', '5'];
    for (const key of preferredKeys) {
      const nested = extractUrlFromUnknownValue(value[key], false);
      if (nested) return nested;
    }

    for (const key of Object.keys(value)) {
      const nested = extractUrlFromUnknownValue(value[key], false);
      if (nested) return nested;
    }
  }

  return normalizeSharedUrl(String(value), false);
}

export function extractSharedUrlFromWantLike(want) {
  if (!want || typeof want !== 'object') {
    return '';
  }

  const uriText = readStringValue(want.uri);
  const normalizedUri = normalizeSharedUrl(uriText, true);
  if (normalizedUri) {
    return normalizedUri;
  }

  const params = want.parameters && typeof want.parameters === 'object' ? want.parameters : {};
  const keys = [
    'ohos.extra.param.key.shareUrl',
    'ohos.extra.param.key.shareAbstract',
    'ability.params.stream',
    'ability.params.streams',
    'ability.params.intent',
    'url',
    'URL',
    'link',
    'shareUrl',
    'text',
    'content',
    'android.intent.extra.TEXT',
  ];

  for (const key of keys) {
    const allowHostFallback = key === 'text' || key === 'content' || key === 'android.intent.extra.TEXT';
    const normalized = extractUrlFromUnknownValue(params[key], allowHostFallback);
    if (normalized) {
      return normalized;
    }
  }

  for (const key of Object.keys(params)) {
    const normalized = extractUrlFromUnknownValue(params[key]);
    if (normalized) return normalized;
  }

  return '';
}
