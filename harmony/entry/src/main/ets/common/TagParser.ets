/**
 * Pure tag input manipulation: parsing, dedup, toggle, append, remove.
 *
 * Previously embedded in Index.ets as private methods on the @Component struct.
 * Extracted here for testability and reuse.
 */

/**
 * Normalize a raw tag candidate: trim and strip leading # characters.
 */
export function normalizedTagCandidate(rawValue: string): string {
  return rawValue.trim().replace(/^#+/, '');
}

/**
 * Join an array of tags into a comma-separated string.
 */
export function normalizedTagsInput(tags: Array<string>): string {
  return tags.join(', ');
}

/**
 * Parse a raw tag input string into a deduplicated array of tag names.
 * Splits on newlines and commas, normalizes each, deduplicates case-insensitively.
 */
export function parseTagsFromInput(rawInput: string): Array<string> {
  const rawItems = rawInput
    .split(/[\n,]/)
    .map((item) => normalizedTagCandidate(item))
    .filter((item) => item.length > 0);
  const deduped: Array<string> = [];

  rawItems.forEach((item) => {
    const exists = deduped.some((current) => current.toLowerCase() === item.toLowerCase());
    if (!exists) {
      deduped.push(item);
    }
  });

  return deduped;
}

/**
 * Append a tag to a raw input string if not already present (case-insensitive).
 */
export function appendTagToInput(rawInput: string, rawTag: string): string {
  const candidate = normalizedTagCandidate(rawTag);
  if (candidate.length === 0) {
    return rawInput;
  }

  const nextTags = parseTagsFromInput(rawInput);
  const exists = nextTags.some((item) => item.toLowerCase() === candidate.toLowerCase());
  if (!exists) {
    nextTags.push(candidate);
  }

  return normalizedTagsInput(nextTags);
}

/**
 * Remove a tag from a raw input string (case-insensitive).
 */
export function removeTagFromInput(rawInput: string, rawTag: string): string {
  const candidate = normalizedTagCandidate(rawTag);
  const nextTags = parseTagsFromInput(rawInput)
    .filter((item) => item.toLowerCase() !== candidate.toLowerCase());
  return normalizedTagsInput(nextTags);
}

/**
 * Toggle a tag in a raw input string: remove if present, append if absent.
 */
export function toggleTagInInput(rawInput: string, rawTag: string): string {
  const candidate = normalizedTagCandidate(rawTag);
  const exists = parseTagsFromInput(rawInput)
    .some((item) => item.toLowerCase() === candidate.toLowerCase());
  return exists ? removeTagFromInput(rawInput, rawTag) : appendTagToInput(rawInput, rawTag);
}

/**
 * Parse tags and include a pending query as a candidate tag if not already present.
 */
export function tagsIncludingPendingQuery(rawInput: string, rawQuery: string): Array<string> {
  const parsed = parseTagsFromInput(rawInput);
  const candidate = normalizedTagCandidate(rawQuery);
  if (candidate.length === 0) {
    return parsed;
  }

  const exists = parsed.some((item) => item.toLowerCase() === candidate.toLowerCase());
  if (!exists) {
    parsed.push(candidate);
  }

  return parsed;
}

/**
 * Check if a tag can be created: non-empty, not already in selected or library.
 */
export function canCreateTag(rawQuery: string, selectedTags: Array<string>, libraryTags: Array<string>): boolean {
  const candidate = normalizedTagCandidate(rawQuery);
  if (candidate.length === 0) {
    return false;
  }

  const existsInSelected = selectedTags.some((tag) => tag.toLowerCase() === candidate.toLowerCase());
  const existsInLibrary = libraryTags.some((tag) => tag.toLowerCase() === candidate.toLowerCase());
  return !existsInSelected && !existsInLibrary;
}

/**
 * Return the pending tag candidate if it's not already selected, or empty string.
 */
export function pendingTagCandidate(rawQuery: string, selectedTags: Array<string>): string {
  const candidate = normalizedTagCandidate(rawQuery);
  if (candidate.length === 0) {
    return '';
  }

  const existsInSelected = selectedTags.some((tag) => tag.toLowerCase() === candidate.toLowerCase());
  return existsInSelected ? '' : candidate;
}

/**
 * Build a list of tag options filtered by query, merging selected and library tags.
 */
export function quickTagOptions(rawQuery: string, selectedTags: Array<string>, libraryTags: Array<string>): Array<string> {
  const query = normalizedTagCandidate(rawQuery).toLowerCase();
  const options: Array<string> = [];

  selectedTags.forEach((tag) => {
    if (query.length === 0 || tag.toLowerCase().indexOf(query) >= 0) {
      options.push(tag);
    }
  });

  libraryTags.forEach((tag) => {
    const exists = options.some((item) => item.toLowerCase() === tag.toLowerCase());
    if (!exists && (query.length === 0 || tag.toLowerCase().indexOf(query) >= 0) ) {
      options.push(tag);
    }
  });

  return options;
}
