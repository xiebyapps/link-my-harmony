/**
 * Collection matching by query string.
 *
 * Previously embedded in Index.ets as a private method.
 * Extracted here for testability and reuse.
 */
import type { CollectionItem } from './Models';

/**
 * Find the best matching collection for a raw query string.
 * Tries exact name match first, then single partial match.
 * Returns null if no match or ambiguous.
 */
export function matchedCollectionByQuery(
  collections: Array<CollectionItem>,
  rawQuery: string,
): CollectionItem | null {
  const query = rawQuery.trim().toLowerCase();
  if (query.length === 0) {
    return null;
  }

  const exactMatch = collections.find((item) => item.name.toLowerCase() === query);
  if (exactMatch !== undefined) {
    return exactMatch;
  }

  const partialMatches = collections.filter((item) => item.name.toLowerCase().indexOf(query) >= 0);
  if (partialMatches.length === 1) {
    return partialMatches[0];
  }

  return null;
}

/**
 * Return the display label for a collection query.
 * Returns 'Unorganized' for empty query, matched collection name, or the raw query.
 */
export function collectionLabelForQuery(
  collections: Array<CollectionItem>,
  rawQuery: string,
): string {
  const query = rawQuery.trim();
  if (query.length === 0) {
    return 'Unorganized';
  }

  const matched = matchedCollectionByQuery(collections, query);
  return matched === null ? query : matched.name;
}
