# sveltekit-boilerplate — design

## 1. What the template is

SvelteKit `1.0.0-next.428` (August 2022) with `adapter-auto`, Svelte 3 and
Vite 3. Three routes: `/` is prerendered and renders `Counter.svelte` (a
`svelte/motion` spring); `/about` is prerendered with `hydrate = dev` and
`router = browser`, so production ships no JavaScript for it; `/todos` has
a `+page.server.js` whose `load` fetches the visitor's list from
`api.svelte.dev` and whose `POST`/`PATCH`/`DELETE` exports (reached through
`methodOverride` and `?_method=`) create, update and delete todos there.
`src/hooks.js` gives every visitor a `userid` cookie; `src/lib/form.js` is
a hand-rolled `enhance` action for those forms; `src/lib/vitals.js` posts
Web Vitals to Vercel's analytics endpoint with a `VERCEL_ANALYTICS_ID`
that `vite.config.js` injects through `define`; `vercel.json` names the
output directory. `Header.svelte` reads `$page` from `$app/stores` and
prefetches with `sveltekit:prefetch`.

## 2. The mapping (Vercel → Cloudflare)

| Vercel primitive the template uses | Here |
|---|---|
| `@sveltejs/adapter-auto` (→ `adapter-vercel` on Vercel: a serverless function plus the prerendered pages on the CDN) | `@sveltejs/adapter-cloudflare`: the Worker at `.svelte-kit/cloudflare/_worker.js`, the static output beside it (`index.html`, `about.html`, `_app/immutable/*`, the `static/` files, `_headers`, `.assetsignore`); the committed `wrangler.jsonc` (`main`, `assets` + `ASSETS`, `nodejs_compat`, compatibility date 2026-10-01) is the deployable config |
| `web-vitals` → `vitals.vercel-analytics.com` with `VERCEL_ANALYTICS_ID` | The Cloudflare Web Analytics beacon in `+layout.svelte`, rendered when `PUBLIC_CF_BEACON_TOKEN` is set at build time (declared in `src/env.js` as public + static with an empty default); `vitals.js`, `web-vitals` and the `define` go |
| `vercel.json` (`outputDirectory: public`) | Nothing: `wrangler.jsonc` names the adapter's output directory |
| Prerendered `/` and `/about` served by the CDN | Served by Static Assets before the Worker runs; `/todos`, the actions and the 404 page run in the Worker |
| Node.js serverless runtime for the hook, `load` and the actions | `nodejs_compat` on the Worker; `crypto.randomUUID`, `fetch` and `FormData` are Workers natives |
| Deploy on push | Orun: `apps/web/component.yaml` (`cloudflare-workers-assets-turbo`) deploys `sveltekit-boilerplate-web-{stage,prod}` on merge to `main` once the product is linked |

The demo API (`https://api.svelte.dev`, `src/routes/todos/api.js`) is an
external service, not a Vercel primitive, and stays as written.

Alternative rejected: `@sveltejs/adapter-static` + assets only. It would
drop `/todos` — the server `load`, the actions, the hook's cookie — which
is the point of the demo.

### What SvelteKit 3 demands

The template predates SvelteKit 1.0; the current adapter needs Kit 3.
Each move below is the framework's, not Cloudflare's, and is the smallest
one that builds:

| 1.0-next.428 | SvelteKit 3 |
|---|---|
| `svelte.config.js` with `kit.adapter` and `kit.methodOverride` | `sveltekit({ adapter })` in `vite.config.js` (the file is no longer read); `methodOverride` no longer exists |
| `src/hooks.js` `handle` | `src/hooks.server.js`, the `Handle` type from `@sveltejs/kit/hooks`; the body is unchanged |
| `$lib/Counter.svelte`, `$lib/header/Header.svelte` | `#lib/…` (declared in `package.json` `imports`, extensions required) |
| `$page` from `$app/stores`; `sveltekit:prefetch` | `page` from `$app/state`; `data-sveltekit-preload-data="hover"` |
| `hydrate = dev`, `router = browser` (about) | `csr = dev`; the router option is gone (the client router is always on); `$app/env` is the module's name again |
| `export const POST/PATCH/DELETE` + `?_method=PATCH` (todos) | `export const actions = { create, update, delete }` + `?/create`, `?/update`, `?/delete` |
| `throw error(status)` | `error(status)` |
| `enhance` from `$lib/form` with `pending`/`result` callbacks | `enhance` from `$app/forms`: the submit callback does what `pending` did; the default behaviour resets the form and refreshes the data, which is what `result` did |
| `jsconfig.json` extending `.svelte-kit/tsconfig.json` | extending `$app/tsconfig`, with its own `include` |
| `cookie ^0.4` + `@types/cookie` | `cookie ^1.1` (bundled types); 2.x renamed `parse`/`serialize` |

The components keep Svelte 3 syntax (`export let`, `$:`, `on:click`,
`<slot />`, `spring`): Svelte 5 runs it in legacy mode, and migrating them
to runes is not something the port needs.

## 3. The repository

```
apps/web               the boilerplate (src/, static/) + the Cloudflare adapter
  vite.config.js       sveltekit({ adapter: cloudflare }) and the vitest include
  src/env.js           PUBLIC_CF_BEACON_TOKEN, public + static, empty by default
  wrangler.jsonc       worker name, compatibility date and flags, main, the ASSETS binding
  component.yaml       build with turbo, deploy wrangler.jsonc, smoke /
  src/lib/Counter.test.js   svelte/server render of the counter
```

No `tests/` package: Svelte components compile only through the Svelte
Vite plugin, so vitest runs in `apps/web` on the app's own `vite.config.js`
and `pnpm test` runs it there.

## 4. The build

`pnpm --filter @app/web build` = `vite build` → the client and server
bundles under `.svelte-kit/output/`, the prerender of `/` and `/about`,
then the adapter writes `.svelte-kit/cloudflare/`: `_worker.js` (the
Worker), `index.html` and `about.html`, `_app/immutable/*` (hashed
assets), the `static/` files, `_headers` (immutable caching for
`/_app/immutable/*`) and `.assetsignore` (keeps `_worker.js` out of the
asset upload). The Orun component deploys the committed `wrangler.jsonc`
with `--name sveltekit-boilerplate-web-<env>`. Locally, `pnpm --filter
@app/web preview` runs `wrangler dev` over the same config.

## 5. Out of scope

Migrating the components to Svelte 5 runes, replacing the hosted demo API
with a Cloudflare binding (the obvious next step for a real app), a custom
domain, and the `_routes.json` the adapter still writes for Pages.
