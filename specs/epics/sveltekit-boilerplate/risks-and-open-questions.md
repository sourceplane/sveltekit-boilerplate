# sveltekit-boilerplate — risks and open questions

## SK-A — SvelteKit 1.0-next → 3 (RESOLVED)

The template is `@sveltejs/kit 1.0.0-next.428` on Svelte 3 and Vite 3;
the current Cloudflare adapter (8) needs SvelteKit 3 (released 2026-10-06),
which needs Svelte 5, Vite 8 and TypeScript 6. The port uses the current
majors and makes only the moves the framework demands (the table in
`design.md`); the components keep their Svelte 3 syntax under Svelte 5's
legacy mode. The build, the checks and the preview verify it. SvelteKit
2.70 with adapter 7 is the fallback: it would keep `svelte.config.js` and
`$lib` but need the same action, hook and store migrations.

## SK-B — The hosted demo API (ACCEPTED, documented)

`/todos` talks to `https://api.svelte.dev`, an external service the
template does not own. On 2026-10-15 it answers `500 {"message":"Invalid
URL string."}` to every request, so `load` calls `error(500)` and the
page renders SvelteKit's 500 page — under `wrangler dev` here exactly as
it would on Vercel today. The hook, the `load`, the actions and the
cookie all run; the client is kept as written. Replacing the API with a
KV-backed store is the obvious follow-up for a real app, not this port.

## SK-C — Svelte 5 legacy mode (RESOLVED)

`Counter.svelte`, the pages and the layout use `export let`, `$:`,
`on:click`, `<slot />` and `spring`. Svelte 5 compiles them in legacy
mode; `svelte-check` reports no errors and three warnings for the
template's self-closing `<button />` tags, which are kept as written.
`page` from `$app/state` is read in `Header.svelte`'s template, which
tracks it in either mode.

## SK-D — Environment variables in SvelteKit 3 (RESOLVED)

`$env/static/public` fails the build when the variable is unset and
`$env/dynamic/*` is refused on prerendered pages (the layout renders for
`/` and `/about`). SvelteKit 3's `src/env.js` declares
`PUBLIC_CF_BEACON_TOKEN` as public and static with an empty default, and
the layout imports it from `$app/env/public`: unset → no beacon markup in
the bundle.

## SK-E — Tests inside the app (SETTLED)

Svelte components compile only through the Svelte Vite plugin, so vitest
runs in `apps/web` on the app's `vite.config.js` (node environment,
`svelte/server` `render`). The repository convention of a separate
`tests/<app>` package is kept for the Next.js ports; here it would only
add a second Svelte toolchain.

## SK-F — Formatting (NOTED)

Upstream's `lint` is `prettier --check .`, and upstream's own `.svelte`
files are tab-indented against its `.prettierrc` (`useTabs: false`), so
the check never passed there. The port keeps the script, names the
Svelte plugin (prettier 3 does not autoload it) and formats the tree once
with the template's own settings — whitespace only.

## SK-G — `nodejs_compat` for the adapter's `nodejs_als` (ACCEPTED)

The adapter's docs ask for `nodejs_als` (AsyncLocalStorage);
`nodejs_compat` is the superset the repository convention uses and the
one the other ports carry.
