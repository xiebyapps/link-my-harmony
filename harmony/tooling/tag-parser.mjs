/**
 * Pure-JS mirror of common/TagParser.ets
 *
 * Pure tag input manipulation: parsing, dedup, toggle, append, remove.
 */

export function normalizedTagCandidate(rawValue) {
  if (typeof rawValue !== 'string') return '';
  return rawValue.trim().replace(/^#+/, '');
}

export function normalizedTagsInput(tags) {
  if (!Array.isArray(tags)) return '';
  return tags.join(', ');
}

export function parseTagsFromInput(rawInput) {
  if (typeof rawInput !== 'string') return [];
  const rawItems = rawInput
    .split(/[\n,]/)
    .map((item) => normalizedTagCandidate(item))
    .filter((item) => item.length > 0);
  const deduped = [];

  rawItems.forEach((item) => {
    const exists = deduped.some((current) => current.toLowerCase() === item.toLowerCase());
    if (!exists) {
      deduped.push(item);
    }
  });

  return deduped;
}

export function appendTagToInput(rawInput, rawTag) {
  const candidate = normalizedTagCandidate(rawTag);
  if (candidate.length === 0) return rawInput ?? '';

  const nextTags = parseTagsFromInput(rawInput ?? '');
  const exists = nextTags.some((item) => item.toLowerCase() === candidate.toLowerCase());
  if (!exists) {
    nextTags.push(candidate);
  }

  return normalizedTagsInput(nextTags);
}

export function removeTagFromInput(rawInput, rawTag) {
  const candidate = normalizedTagCandidate(rawTag);
  const nextTags = parseTagsFromInput(rawInput ?? '')
    .filter((item) => item.toLowerCase() !== candidate.toLowerCase());
  return normalizedTagsInput(nextTags);
}

export function toggleTagInInput(rawInput, rawTag) {
  const candidate = normalizedTagCandidate(rawTag);
  const exists = parseTagsFromInput(rawInput ?? '')
    .some((item) => item.toLowerCase() === candidate.toLowerCase());
  return exists ? removeTagFromInput(rawInput, rawTag) : appendTagToInput(rawInput, rawTag);
}

export function tagsIncludingPendingQuery(rawInput, rawQuery) {
  const parsed = parseTagsFromInput(rawInput ?? '');
  const candidate = normalizedTagCandidate(rawQuery);
  if (candidate.length === 0) return parsed;

  const exists = parsed.some((item) => item.toLowerCase() === candidate.toLowerCase());
  if (!exists) {
    parsed.push(candidate);
  }

  return parsed;
}

export function canCreateTag(rawQuery, selectedTags, libraryTags) {
  const candidate = normalizedTagCandidate(rawQuery);
  if (candidate.length === 0) return false;

  const safeSelected = Array.isArray(selectedTags) ? selectedTags : [];
  const safeLibrary = Array.isArray(libraryTags) ? libraryTags : [];
  const existsInSelected = safeSelected.some((tag) => tag.toLowerCase() === candidate.toLowerCase());
  const existsInLibrary = safeLibrary.some((tag) => tag.toLowerCase() === candidate.toLowerCase());
  return !existsInSelected && !existsInLibrary;
}

export function pendingTagCandidate(rawQuery, selectedTags) {
  const candidate = normalizedTagCandidate(rawQuery);
  if (candidate.length === 0) return '';

  const safeSelected = Array.isArray(selectedTags) ? selectedTags : [];
  const existsInSelected = safeSelected.some((tag) => tag.toLowerCase() === candidate.toLowerCase());
  return existsInSelected ? '' : candidate;
}

export function quickTagOptions(rawQuery, selectedTags, libraryTags) {
  const query = normalizedTagCandidate(rawQuery).toLowerCase();
  const safeSelected = Array.isArray(selectedTags) ? selectedTags : [];
  const safeLibrary = Array.isArray(libraryTags) ? libraryTags : [];
  const options = [];

  safeSelected.forEach((tag) => {
    if (query.length === 0 || tag.toLowerCase().indexOf(query) >= 0) {
      options.push(tag);
    }
  });

  safeLibrary.forEach((tag) => {
    const exists = options.some((item) => item.toLowerCase() === tag.toLowerCase());
    if (!exists && (query.length === 0 || tag.toLowerCase().indexOf(query) >= 0)) {
      options.push(tag);
    }
  });

  return options;
}
