import { fail } from '@sveltejs/kit';
import { MAX_TODOS, clean, newUid, read, write } from './store.js';

/**
 * @typedef {import('./store.js').Todo & { pending_delete: boolean }} Todo
 */

const TOO_BIG =
  'That would not fit in the cookie this list is kept in — finish or delete a todo first.';

/** @type {import('./$types').PageServerLoad} */
export const load = async ({ cookies }) => {
  // The visitor's list comes from their own cookie (./store.js).
  return {
    /** @type {Todo[]} */
    todos: read(cookies).map((todo) => ({ ...todo, pending_delete: false }))
  };
};

/** @type {import('./$types').Actions} */
export const actions = {
  create: async ({ request, cookies }) => {
    const form = await request.formData();
    const text = clean(form.get('text'));
    if (!text) return fail(400, { error: 'A todo needs some text.' });

    const todos = read(cookies);
    if (todos.length >= MAX_TODOS) {
      return fail(400, {
        error: `The list holds ${MAX_TODOS} todos — finish or delete one first.`
      });
    }
    todos.push({ uid: newUid(todos), text, done: false });
    if (!write(cookies, todos)) return fail(400, { error: TOO_BIG });
  },

  update: async ({ request, cookies }) => {
    const form = await request.formData();
    const todos = read(cookies);
    const todo = todos.find((t) => t.uid === form.get('uid'));
    if (!todo) return fail(404, { error: 'No such todo.' });

    if (form.has('text')) {
      const text = clean(form.get('text'));
      if (text) todo.text = text;
    }
    if (form.has('done')) todo.done = !!form.get('done');
    if (!write(cookies, todos)) return fail(400, { error: TOO_BIG });
  },

  delete: async ({ request, cookies }) => {
    const form = await request.formData();
    const todos = read(cookies);
    write(
      cookies,
      todos.filter((t) => t.uid !== form.get('uid'))
    );
  }
};
