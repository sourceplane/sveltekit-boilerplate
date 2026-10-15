import { render } from 'svelte/server';
import { expect, it } from 'vitest';
import Home from '../routes/+page.svelte';
import About from '../routes/about/+page.svelte';
import { SITE_NAME, pageTitle } from './site.js';

/** @param {string} html */
const text = (html) =>
  html
    .replace(/<[^>]+>/g, ' ')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&')
    .replace(/\s+/g, ' ')
    .trim();

it('names the site', () => {
  expect(SITE_NAME.trim()).not.toBe('');
});

it('titles a page after the page, then the site', () => {
  expect(pageTitle()).toBe(SITE_NAME);
  expect(pageTitle('About')).toBe(`About | ${SITE_NAME}`);
});

it("puts the site's name in the home page's heading and title", () => {
  const { head, body } = render(Home);
  const h1 = /<h1[^>]*>([\s\S]*?)<\/h1>/.exec(body);
  expect(h1 && text(h1[1])).toBe(`to your new ${SITE_NAME}`);
  const title = /<title>([\s\S]*?)<\/title>/.exec(head);
  expect(title && text(title[1])).toBe(SITE_NAME);
});

it("titles the about page through the site's name", () => {
  const { head } = render(About);
  const title = /<title>([\s\S]*?)<\/title>/.exec(head);
  expect(title && text(title[1])).toBe(`About | ${SITE_NAME}`);
});
