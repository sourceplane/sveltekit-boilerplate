// The todos live with the visitor: one httpOnly cookie, scoped to /todos,
// holding the list as JSON — base64url-encoded, so every byte of it is
// cookie-safe. No database and no third party (the template's hosted demo
// store, api.svelte.dev, is gone), and every action still works without
// JavaScript, because the cookie rides along with a plain form POST.
//
// A browser keeps about 4 KB per cookie, so the list is capped: at most
// MAX_TODOS todos, each cut to MAX_TEXT characters, and a change that would
// push the encoded list past MAX_COOKIE bytes is refused rather than written
// (a cookie over the limit is dropped by the browser, list and all).

export const COOKIE = 'todos';
export const MAX_TODOS = 50;
export const MAX_TEXT = 100;
export const MAX_COOKIE = 3800;

/** @typedef {{ uid: string; text: string; done: boolean }} Todo */

/** @param {string} value */
function toBase64url(value) {
  let binary = '';
  for (const byte of new TextEncoder().encode(value)) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** @param {string} value */
function fromBase64url(value) {
  const binary = atob(value.replace(/-/g, '+').replace(/_/g, '/'));
  return new TextDecoder().decode(Uint8Array.from(binary, (c) => c.charCodeAt(0)));
}

/**
 * A todo's text as it is kept: control characters out, trimmed, and cut to
 * MAX_TEXT characters (code points, so a character is never split).
 * @param {unknown} value
 */
export function clean(value) {
  const text = String(value ?? '')
    .replace(/[\u0000-\u001f\u007f]/g, ' ')
    .trim();
  return Array.from(text).slice(0, MAX_TEXT).join('');
}

/**
 * The list a cookie value holds. Anything malformed — a cookie from an older
 * shape, or one edited by hand — reads as what can be salvaged from it.
 * @param {string | undefined} raw
 * @returns {Todo[]}
 */
export function parse(raw) {
  if (!raw) return [];
  let rows;
  try {
    rows = JSON.parse(fromBase64url(raw));
  } catch {
    return [];
  }
  if (!Array.isArray(rows)) return [];
  /** @type {Todo[]} */
  const todos = [];
  for (const row of rows) {
    if (!Array.isArray(row) || typeof row[0] !== 'string' || typeof row[1] !== 'string') continue;
    if (todos.some((t) => t.uid === row[0])) continue;
    todos.push({ uid: row[0].slice(0, 16), text: clean(row[1]), done: !!row[2] });
    if (todos.length === MAX_TODOS) break;
  }
  return todos;
}

/**
 * The cookie value for a list: compact rows of [uid, text, done].
 * @param {Todo[]} todos
 */
export function serialize(todos) {
  return toBase64url(JSON.stringify(todos.map((t) => [t.uid, t.text, t.done ? 1 : 0])));
}

/** @param {Todo[]} todos */
export function newUid(todos) {
  /** @type {string} */
  let uid;
  do uid = crypto.randomUUID().slice(0, 8);
  while (todos.some((t) => t.uid === uid));
  return uid;
}

/** @param {import('@sveltejs/kit').Cookies} cookies */
export function read(cookies) {
  return parse(cookies.get(COOKIE));
}

/**
 * Write the list back, or refuse (false) if it would not fit in the cookie.
 * @param {import('@sveltejs/kit').Cookies} cookies
 * @param {Todo[]} todos
 */
export function write(cookies, todos) {
  const options = /** @type {const} */ ({ path: '/todos', httpOnly: true, sameSite: 'lax' });
  if (todos.length === 0) {
    cookies.delete(COOKIE, options);
    return true;
  }
  const value = serialize(todos);
  if (value.length > MAX_COOKIE) return false;
  cookies.set(COOKIE, value, { ...options, maxAge: 60 * 60 * 24 * 365 });
  return true;
}
