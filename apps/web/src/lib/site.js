// The site's name, written once: the home page's heading and every page's
// <title> read SITE_NAME. A site made from this repository gets it rewritten
// to its own name, as a JSON string so that any name (an apostrophe or an
// ampersand included) stays a valid one, so keep it a literal on one line.
// The rewrite writes double quotes and this app's prettier prefers single
// ones, hence the ignore.
// prettier-ignore
export const SITE_NAME = "SvelteKit app";

/**
 * A page's <title>: the page, then the site. The home page is the site.
 * @param {string} [page]
 */
export function pageTitle(page) {
  return page ? `${page} | ${SITE_NAME}` : SITE_NAME;
}
