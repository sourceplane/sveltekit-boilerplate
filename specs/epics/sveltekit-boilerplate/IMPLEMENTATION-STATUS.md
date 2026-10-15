# sveltekit-boilerplate (SK) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| SK0 — the spec | ✅ Shipped | [#1](https://github.com/sourceplane/sveltekit-boilerplate/pull/1) |
| SK1 — the site on Workers | ✅ Shipped | [#2](https://github.com/sourceplane/sveltekit-boilerplate/pull/2) |
| SK2 — ready to instantiate | ✅ Shipped | [#3](https://github.com/sourceplane/sveltekit-boilerplate/pull/3) |

## Departures from the upstream template

### `@sveltejs/adapter-cloudflare` for `@sveltejs/adapter-auto`

`vite.config.js`: `sveltekit({ adapter: adapter() })`. The committed
`wrangler.jsonc` (`main .svelte-kit/cloudflare/_worker.js`, `assets
.svelte-kit/cloudflare` + `ASSETS`, `nodejs_compat`, compatibility date
2026-10-01) is the deployable config. `vercel.json` is not copied.

### SvelteKit 1.0-next.428 → 3, Svelte 3 → 5, Vite 3 → 8

The framework-forced moves, file by file (the full table is in
`design.md`): `svelte.config.js` → `vite.config.js` (`methodOverride`
gone); `src/hooks.js` → `src/hooks.server.js` (`Handle` from
`@sveltejs/kit/hooks`, body unchanged); `$lib/…` → `#lib/…` (`package.json`
`imports`); `$app/stores` → `$app/state` and `sveltekit:prefetch` →
`data-sveltekit-preload-data="hover"` in `Header.svelte`; `hydrate = dev`
→ `csr = dev` and `router = browser` dropped in `about/+page.js`; the
todos `POST`/`PATCH`/`DELETE` exports + `?_method=` → `actions = { create,
update, delete }` + `?/create` etc., `throw error()` → `error()`;
`jsconfig.json` extends `$app/tsconfig`; `typescript ^4.7` → `^6.0`,
`svelte-check ^2.7` → `^4.7`, `@sveltejs/vite-plugin-svelte ^7` added (a
peer of Kit 3). The `svelte-kit package` script is dropped (it moved to
`@sveltejs/package`; the template has nothing to package).

### `$app/forms` `enhance` for `src/lib/form.js`

The template's hand-rolled `enhance` spoke the pre-1.0 action protocol
(a JSON-accepting fetch, then `invalidate(url)`), which no longer reruns
the server `load`. `todos/+page.svelte` uses Kit's `enhance`: the submit
callback carries the optimistic `pending` updates, the default behaviour
covers `result: form.reset()`. `form.js` is deleted.

### The Cloudflare Web Analytics beacon for `web-vitals`

`src/lib/vitals.js`, the `web-vitals` dependency and the
`VERCEL_ANALYTICS_ID` `define` are gone; `+layout.svelte` renders the
beacon script in `<svelte:head>` when `PUBLIC_CF_BEACON_TOKEN` (declared
in `src/env.js`, public + static, empty by default) is set at build.

### `cookie ^1.1` for `^0.4`, `@types/cookie` dropped

The hook's `cookie.parse`/`cookie.serialize` are unchanged; 1.x ships its
types, and 2.x (what Kit 3 itself depends on) renamed the functions.

### Formatted once with the template's own prettier settings

prettier 3 + `prettier-plugin-svelte` 4 named in `.prettierrc`; the
template's `.svelte` files were tab-indented against its `useTabs: false`,
so `prettier --write .` ran once — whitespace-only changes to
`Counter.svelte`, `app.css`, `app.html` and the edited pages — and `lint`
(`prettier --check .`) passes as upstream intended.

### Scripts

`preview` is `wrangler dev --config wrangler.jsonc` (upstream: `vite
preview`, which has no Workers runtime); `typecheck` is upstream's `check`
(`svelte-check`) after `svelte-kit sync`; `test` is `vitest run`;
`prepare` runs `svelte-kit sync`. `dev`, `build`, `check`, `check:watch`,
`lint` and `format` are upstream's.

### The app's `.gitignore` and lockfile are not copied

The repository's root `.gitignore` covers `.svelte-kit/`; the workspace
lockfile replaces the template's.

## Verified

- Local: `svelte-check` (0 errors; 3 warnings for the template's self-closing
  `<button />`), `prettier --check`, `pnpm test` (1 test, a `svelte/server`
  render of the counter), `pnpm build` green; `wrangler dev --config
  wrangler.jsonc`: `/` 200 ("to your new SvelteKit app", no beacon markup),
  `/about` 200 with no `<script>`, `/svelte-welcome.webp` 200 (`image/webp`),
  `/favicon.png` 200, `/_app/immutable/entry/start.*.js` 200, `/nope` 404
  (SvelteKit's error page from the Worker). `/todos`: the hook sets the
  `userid` cookie, the server `load` runs and renders SvelteKit's 500 page
  because `api.svelte.dev` answers `500 Invalid URL string.` to every request
  (checked directly on 2026-10-15; SK-B); `POST /todos?/create` runs the
  action. A fresh clone of #2's head: `pnpm install --frozen-lockfile`,
  typecheck, lint, test, build green.
- CI: `Checks` green on #1, #2 and on every push to `main`.
- Not verified: a live deploy (gated until the product is linked to an Orun
  workspace with a Cloudflare connection); the beacon with a real token; the
  todos flow end to end and the enhanced forms in a browser (both need a
  working demo API — SK-B).

## Versions

| Package | Version | Why |
|---|---|---|
| @sveltejs/kit | ^3.0.1 | the current major (2026-10-06); the template is `1.0.0-next.428`; the current adapter needs Kit 3 |
| @sveltejs/adapter-cloudflare | ^8.0.0 | emits `_worker.js` + the static output; needs Kit 3 and wrangler ≥ 4.67 |
| svelte | ^5.57.2 | Kit 3's minimum is 5.57.1; the template's Svelte 3 syntax runs in legacy mode |
| vite, @sveltejs/vite-plugin-svelte | ^8.3.4, ^7.3.1 | Kit 3's requirements (the template: Vite 3) |
| typescript | ^6.0.3 | Kit 3's stated requirement (an optional peer); svelte-check 4.7 accepts ^5 and ^6; the root tooling stays on 5.9 |
| svelte-check | ^4.7.6 | the template's `check` script, current major (the template: `^2.7`) |
| prettier, prettier-plugin-svelte | ^3.9.10, ^4.1.1 | the template's `lint`; prettier 3 needs the plugin named in `.prettierrc` |
| cookie | ^1.1.1 | the template's `parse`/`serialize` with bundled types; 2.x renamed them |
| @fontsource/fira-mono | ^4.5.0 | as upstream |
| vitest | ^5.0.4 | current; runs on the app's `vite.config.js` |
| wrangler | ^4.151.0 | compatibility_date 2026-10-01 |
