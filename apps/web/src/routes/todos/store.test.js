import { describe, expect, it } from 'vitest';
import { actions, load } from './+page.server.js';
import {
  COOKIE,
  MAX_COOKIE,
  MAX_TEXT,
  MAX_TODOS,
  clean,
  parse,
  serialize,
  write
} from './store.js';

/** A cookie jar standing in for SvelteKit's `cookies`, keeping what was set. */
function jar(initial = {}) {
  /** @type {Record<string, string>} */
  const values = { ...initial };
  /** @type {Record<string, any>} */
  const options = {};
  return {
    values,
    options,
    get: (/** @type {string} */ name) => values[name],
    set: (/** @type {string} */ name, /** @type {string} */ value, /** @type {any} */ opts) => {
      values[name] = value;
      options[name] = opts;
    },
    delete: (/** @type {string} */ name) => {
      delete values[name];
    }
  };
}

/** @param {Record<string, string>} fields */
const post = (fields) => ({
  request: new Request('http://localhost/todos', {
    method: 'POST',
    body: new URLSearchParams(fields)
  })
});

/** @param {any} cookies */
const list = async (cookies) =>
  /** @type {{ todos: any[] }} */ (await load(/** @type {any} */ ({ cookies }))).todos;

describe('the todos cookie', () => {
  it('round-trips a list, quotes, ampersands and emoji included', () => {
    const todos = [
      { uid: 'a1', text: 'Sam\'s "notes" & links', done: false },
      { uid: 'b2', text: 'ship it 🚀', done: true }
    ];
    const value = serialize(todos);
    expect(value).toMatch(/^[A-Za-z0-9_-]+$/);
    expect(parse(value)).toEqual(todos);
  });

  it('reads a malformed cookie as an empty list', () => {
    expect(parse(undefined)).toEqual([]);
    expect(parse('not base64 json')).toEqual([]);
    expect(parse(serialize([]).replace(/./, '!'))).toEqual([]);
  });

  it('keeps a text clean and within MAX_TEXT characters', () => {
    expect(clean('  a\u0000b\n ')).toBe('a b');
    expect(Array.from(clean('🚀'.repeat(MAX_TEXT + 10)))).toHaveLength(MAX_TEXT);
  });

  it('refuses a list that would not fit in a cookie, and writes one that does', () => {
    const big = Array.from({ length: MAX_TODOS }, (_, i) => ({
      uid: String(i),
      text: '🚀'.repeat(MAX_TEXT),
      done: false
    }));
    const cookies = jar();
    expect(write(/** @type {any} */ (cookies), big)).toBe(false);
    expect(cookies.values[COOKIE]).toBeUndefined();

    const small = Array.from({ length: MAX_TODOS }, (_, i) => ({
      uid: String(i),
      text: 'milk',
      done: false
    }));
    expect(write(/** @type {any} */ (cookies), small)).toBe(true);
    expect(cookies.values[COOKIE].length).toBeLessThanOrEqual(MAX_COOKIE);
    expect(cookies.options[COOKIE]).toMatchObject({
      path: '/todos',
      httpOnly: true,
      sameSite: 'lax'
    });
  });
});

describe('the todos actions', () => {
  it('create, toggle, edit and delete, each through the cookie', async () => {
    const cookies = jar();
    await actions.create(/** @type {any} */ ({ ...post({ text: 'buy milk' }), cookies }));
    let todos = await list(cookies);
    expect(todos).toMatchObject([{ text: 'buy milk', done: false, pending_delete: false }]);
    const uid = todos[0].uid;

    await actions.update(/** @type {any} */ ({ ...post({ uid, done: 'true' }), cookies }));
    expect((await list(cookies))[0].done).toBe(true);

    await actions.update(/** @type {any} */ ({ ...post({ uid, text: 'buy oat milk' }), cookies }));
    expect((await list(cookies))[0]).toMatchObject({ text: 'buy oat milk', done: true });

    await actions.delete(/** @type {any} */ ({ ...post({ uid }), cookies }));
    expect(await list(cookies)).toEqual([]);
    expect(cookies.values[COOKIE]).toBeUndefined();
  });

  it('refuses an empty todo and a full list', async () => {
    const cookies = jar();
    expect(
      await actions.create(/** @type {any} */ ({ ...post({ text: '  ' }), cookies }))
    ).toMatchObject({
      status: 400
    });
    for (let i = 0; i < MAX_TODOS; i++) {
      await actions.create(/** @type {any} */ ({ ...post({ text: `todo ${i}` }), cookies }));
    }
    expect(await list(cookies)).toHaveLength(MAX_TODOS);
    expect(
      await actions.create(/** @type {any} */ ({ ...post({ text: 'one more' }), cookies }))
    ).toMatchObject({
      status: 400
    });
    expect(await list(cookies)).toHaveLength(MAX_TODOS);
  });
});
