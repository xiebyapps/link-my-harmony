import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  extractUrl,
  extractHostname,
  normalizeUrl,
  extractUrlAndTitle,
  URL_PATTERN,
  HOST_PATTERN,
  URL_TRAILING_NOISE_PATTERN,
} from './url-parser.mjs';

describe('extractUrl', () => {
  it('returns empty for empty input', () => {
    assert.equal(extractUrl(''), '');
    assert.equal(extractUrl('   '), '');
  });

  it('extracts a plain https URL', () => {
    assert.equal(extractUrl('https://example.com'), 'https://example.com');
  });

  it('extracts http URL', () => {
    assert.equal(extractUrl('http://example.com/path?q=1'), 'http://example.com/path?q=1');
  });

  it('strips trailing punctuation', () => {
    assert.equal(extractUrl('https://example.com)'), 'https://example.com');
    assert.equal(extractUrl('https://example.com.'), 'https://example.com');
    assert.equal(extractUrl('https://example.com!'), 'https://example.com');
    assert.equal(extractUrl('https://example.com,"'), 'https://example.com');
  });

  it('extracts URL from mixed text', () => {
    assert.equal(extractUrl('Check this https://example.com out'), 'https://example.com');
  });

  it('returns empty for no URL', () => {
    assert.equal(extractUrl('just some text'), '');
  });
});

describe('extractHostname', () => {
  it('returns empty for empty input', () => {
    assert.equal(extractHostname(''), '');
  });

  it('extracts hostname from https URL', () => {
    assert.equal(extractHostname('https://example.com/path'), 'example.com');
  });

  it('strips www prefix', () => {
    assert.equal(extractHostname('https://www.example.com'), 'example.com');
  });

  it('strips port', () => {
    assert.equal(extractHostname('https://example.com:8080/path'), 'example.com');
  });

  it('strips auth', () => {
    assert.equal(extractHostname('https://user:pass@example.com/path'), 'example.com');
  });

  it('lowercases hostname', () => {
    assert.equal(extractHostname('https://Example.COM'), 'example.com');
  });

  it('returns empty for non-URL', () => {
    assert.equal(extractHostname('not a url'), '');
  });
});

describe('normalizeUrl', () => {
  it('returns empty for empty input', () => {
    assert.equal(normalizeUrl(''), '');
  });

  it('normalizes a plain URL', () => {
    assert.equal(normalizeUrl('https://example.com'), 'https://example.com');
  });

  it('strips trailing noise', () => {
    assert.equal(normalizeUrl('https://example.com.'), 'https://example.com');
  });

  it('adds https for bare hostname when allowed', () => {
    assert.equal(normalizeUrl('example.com'), 'https://example.com');
  });

  it('does not add https for bare hostname when disallowed', () => {
    assert.equal(normalizeUrl('example.com', false), '');
  });

  it('returns empty for non-URL text when fallback disabled', () => {
    assert.equal(normalizeUrl('just text', false), '');
  });
});

describe('extractUrlAndTitle', () => {
  it('returns empty for empty input', () => {
    assert.deepEqual(extractUrlAndTitle(''), { url: '', title: '' });
  });

  it('extracts URL only', () => {
    assert.deepEqual(extractUrlAndTitle('https://example.com'), {
      url: 'https://example.com',
      title: '',
    });
  });

  it('extracts URL and title', () => {
    assert.deepEqual(extractUrlAndTitle('https://example.com My Bookmark Title'), {
      url: 'https://example.com',
      title: 'My Bookmark Title',
    });
  });

  it('extracts bare hostname with title', () => {
    const result = extractUrlAndTitle('example.com Some Title');
    assert.equal(result.url, 'https://example.com');
    assert.equal(result.title, 'Some Title');
  });

  it('strips trailing noise from URL', () => {
    assert.deepEqual(extractUrlAndTitle('https://example.com. Title here'), {
      url: 'https://example.com',
      title: 'Title here',
    });
  });

  it('truncates title at 200 chars', () => {
    const longTitle = 'A'.repeat(250);
    const result = extractUrlAndTitle(`https://example.com ${longTitle}`);
    assert.equal(result.url, 'https://example.com');
    assert.equal(result.title.length, 200);
  });

  it('normalizes whitespace in title', () => {
    assert.deepEqual(extractUrlAndTitle('https://example.com   lots   of   spaces'), {
      url: 'https://example.com',
      title: 'lots of spaces',
    });
  });
});
