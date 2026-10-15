# sveltekit-boilerplate (SK) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| SK0 — the spec | | |
| SK1 — the site on Workers | | |
| SK2 — ready to instantiate | | |

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
