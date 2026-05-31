// Pure search/filter logic extracted from Index.ets
// Mirrors the ArkTS implementation for testability.

/**
 * Filter collections by search query (case-insensitive name match).
 * @param {Array<{id: number, name: string}>} collections
 * @param {string} query
 * @returns {Array} matching collections
 */
export function filteredCollectionsForSearch(collections, query) {
  const term = query.trim().toLowerCase();
  if (term.length === 0) {
    return [];
  }
  return collections.filter((item) => item.name.toLowerCase().indexOf(term) >= 0);
}

/**
 * Filter tag names by search query (case-insensitive substring match).
 * @param {string[]} tagNames
 * @param {string} query
 * @returns {string[]} matching tag names
 */
export function filteredTagsForSearch(tagNames, query) {
  const term = query.trim().toLowerCase();
  if (term.length === 0) {
    return [];
  }
  return tagNames.filter((tag) => tag.toLowerCase().indexOf(term) >= 0);
}

/**
 * Filter links by search query across title, URL, description, and tags.
 * @param {Array<{name: string, url: string, description: string, tags: Array<{name: string}>}>} links
 * @param {string} query
 * @returns {Array} matching links
 */
export function filteredLinksForSearch(links, query) {
  const term = query.trim().toLowerCase();
  if (term.length === 0) {
    return [];
  }
  return links.filter((item) => {
    const inTitle = item.name.toLowerCase().indexOf(term) >= 0;
    const inUrl = item.url.toLowerCase().indexOf(term) >= 0;
    const inDesc = item.description.toLowerCase().indexOf(term) >= 0;
    const inTags = item.tags.some((tag) => tag.name.toLowerCase().indexOf(term) >= 0);
    return inTitle || inUrl || inDesc || inTags;
  });
}

/**
 * Check if any search result exists across links, collections, and tags.
 * @param {Array} links
 * @param {Array} collections
 * @param {string[]} tags
 * @returns {boolean}
 */
export function searchHasAnyResult(links, collections, tags) {
  return links.length > 0 || collections.length > 0 || tags.length > 0;
}

/**
 * Group preview links by collection and rank by usage score.
 * Produces sections for the dashboard collection previews.
 *
 * @param {Array<{id: number, ownerId: number, name: string, description: string, color: string, parentId: number, parentName: string, linkCount: number}>} collections
 * @param {Array<{collectionId: number, [key: string]: any}>} previewLinks - links to group
 * @param {Array<{collectionId: number, score: number}>} usageEntries - scored usage entries
 * @param {number} now - current timestamp for scoring
 * @param {number} limit - max links per section (default 10)
 * @returns {Array<{collection: object, links: Array}>}
 */
export function collectionPreviewSections(collections, previewLinks, usageEntries, now, limit = 10) {
  const grouped = [];

  collections.forEach((collection) => {
    const links = previewLinks
      .filter((item) => item.collectionId === collection.id)
      .slice(0, limit);

    if (links.length > 0) {
      grouped.push({ collection, links });
    }
  });

  // Rank by usage score (higher = more recently used)
  const ranked = grouped.map((section, i) => {
    const entry = usageEntries.find((e) => e.collectionId === section.collection.id) || null;
    const score = entry !== null ? entry.score : 0;
    return { section, order: i, score };
  });

  ranked.sort((a, b) => {
    if (a.score !== b.score) {
      return b.score - a.score;
    }
    return a.order - b.order;
  });

  const sorted = ranked.map((item) => item.section);

  // Add unorganized links at the end
  const unorganizedLinks = previewLinks
    .filter((item) => item.collectionId === 0)
    .slice(0, limit);

  if (unorganizedLinks.length > 0) {
    sorted.push({
      collection: {
        id: 0,
        ownerId: 0,
        name: 'Unorganized',
        description: '',
        color: '',
        parentId: 0,
        parentName: '',
        linkCount: unorganizedLinks.length,
      },
      links: unorganizedLinks,
    });
  }

  return sorted;
}
