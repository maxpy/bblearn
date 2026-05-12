/**
 * Bible API Worker
 * GET /bible/{version}/{book}/{chapter}
 *   → returns JSON array of {verse, text, start, end} from KV
 *
 * KV key format: bible:{version}:{book}:{chapter}
 * e.g. bible:KJV:41:1  (book is integer, 1-66)
 */

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    // Expected: /bible/{version}/{book}/{chapter}
    const match = url.pathname.match(/^\/bible\/([^/]+)\/(\d+)\/(\d+)$/);
    if (!match) {
      return json({ error: 'Not found. Use /bible/{version}/{book}/{chapter}' }, 404);
    }

    const [, version, book, chapter] = match;
    const key = `bible:${version}:${book}:${chapter}`;

    const value = await env.BBLEARN.get(key);
    if (value === null) {
      return json({ error: `No data for key: ${key}` }, 404);
    }

    return new Response(value, {
      status: 200,
      headers: {
        ...CORS_HEADERS,
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'public, max-age=86400',
      },
    });
  },
};

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
