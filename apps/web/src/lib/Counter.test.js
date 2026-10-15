import { render } from 'svelte/server';
import { expect, it } from 'vitest';
import Counter from './Counter.svelte';

it('renders the counter at zero with its two buttons', () => {
  const { body } = render(Counter);
  expect(body).toMatch(/<strong[^>]*>0<\/strong>/);
  expect(body).toContain('aria-label="Decrease the counter by one"');
  expect(body).toContain('aria-label="Increase the counter by one"');
});
