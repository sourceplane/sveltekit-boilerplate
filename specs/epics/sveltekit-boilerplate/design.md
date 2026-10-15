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
external service, not a Vercel primitive, and stayed as written through
SK2. SK3 replaced it: the service is gone, and the todos now live in the
visitor's own cookie (§6, risks SK-B and SK-L).

Alternative rejected: `@sveltejs/adapter-static` + assets only. It would
drop `/todos` — the server `load` and the actions — which is the point of
the demo.

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

Migrating the components to Svelte 5 runes, a shared todos store (a KV
binding behind `store.js` — the obvious next step for a real app), a
custom-domain component (§6: the brokered deploy token carries no zone
permissions, so attaching a domain is the owner's step), and the
`_routes.json` the adapter still writes for Pages.

## 6. The baseline (SK3)

The repository instantiates new sites the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) instantiates
products, and the way portfolio-starter-kit's `baseline-v2` does — that
conversion is the template, ported file for file and adapted where the
framework differs: a console card (`blueprint.yaml`) the platform renders, a
build document (`repo-blueprint.yaml`) `orun new` runs, and a rename engine
that makes the copy somebody else's.

| Cirrus | portfolio-starter-kit | Here | Why the difference |
|---|---|---|---|
| six phases | three: `01-scaffold`, `02-site`, `03-docs` | the same three | one component deploys; no data plane, no fleet, no bindings |
| — | `02-site` places `web` + `web-tests` | `02-site` places `web` alone | the site's tests run inside `apps/web` (SK-E); there is no `tests/web` to place, retouch or partition |
| `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_D1_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | `CLOUDFLARE_API_TOKEN` (`workers-deploy`), `CLOUDFLARE_ACCOUNT_ID` | the same two | no D1 |
| `07-domain` (parked component) | no domain phase; `SITE_URL` per environment feeds the build | no domain phase, and no `SITE_URL` | the site builds no absolute links (no sitemap, no feed, no Open Graph), so a domain attached in Cloudflare needs nothing from the repository |
| task contracts in `tasks/` | `.baseline/tasks/` | `.baseline/tasks/` | `tasks/` is this repository's own work tree (`intent.yaml` `work:`), where an unkeyed contract is an error |
| ships its own README | ships `.baseline/product/README.md` | the same | this README is about the baseline; a site's owner needs the site's |
| — | `work-tree.mjs` strips `work:` from the site's intent | the same | a site has no `specs/` or `tasks/` |
| stack-tectonic 0.20.0 (lane-scoped install) | 0.19.0 | 0.19.0 | the portfolio's Turbopack build cannot run through 0.20.0's symlinked `node_modules`; this site's Vite build can (measured, SK-J), and the pin keeps the install the first live build proved |
| one push workflow | `checks.yml` on pull requests only | the same | `orun.run/watch@v1` takes the newest run for a commit from any workflow (SK-K) |
| — | ships `tooling/{eslint,tsconfig,wire}` | the same; `tooling/migrations` stays | it checks a `packages/db` manifest; the site has no database and nothing it runs reads it |
| rebrand rules for a SaaS | the source link, the `SITE_NAME` seam, the domain, the subdomain, Worker names, secret refs, the repo slug | the same rules; source links appear in docs only | the site shows no source link (the header's corner is upstream's empty `TODO`) |

**Identity in the app** is one literal in `apps/web/src/lib/site.js`:
`SITE_NAME`, the upstream's own name for the app (`SvelteKit app`, from its
home page's heading). The home page's heading reads `to your new {SITE_NAME}`
and its `<title>` is `SITE_NAME`; the about and todos titles are
`About | SITE_NAME` and `Todos | SITE_NAME` (`pageTitle`). The rename writes
the name with `JSON.stringify`, so any name the card's pattern admits —
apostrophes and ampersands included — stays a valid string; Svelte escapes
it in the markup. The app's prettier prefers single quotes, so the line
carries a `// prettier-ignore` and the rewrite's double quotes pass `lint` in
the site. `src/lib/site.test.js` renders the home and about pages through
`svelte/server` and reads the name back out of them, so it holds in a site
under any name.

**The todos keep their list in the visitor's cookie.** The template's
hosted demo store is gone (`api.svelte.dev` answers 500 to `/todos/<id>` and
404 to `/`), and a site whose nav links a page that fails from day one is
not a baseline. `src/routes/todos/store.js` keeps each visitor's list in one
httpOnly cookie, `path=/todos`, `SameSite=Lax`: the list as JSON rows of
`[uid, text, done]`, base64url-encoded so every byte is cookie-safe. The
server `load` reads it and the three named actions (`create`, `update` for
toggle and edit, `delete`) write it back, so every action still works
without JavaScript and Kit's `enhance` still runs them in place. A browser
keeps about 4 KB per cookie, so the list is capped at 50 todos of 100
characters and a change that would push the encoded value past 3,800 bytes
is refused with a message rather than written. With the API gone, nothing
needs the template's `userid` cookie, so `src/hooks.server.js`, `App.Locals`
and the `cookie` dependency go too.

**The smoke reads structure, not the name**: the home page must carry the
nav's `/todos` link (it is pre-rendered, so this proves the assets), and an
unknown path must be SvelteKit's 404 page (`<h1>404</h1>`, rendered by the
Worker). The name is the owner's to change and HTML-escaped when it carries
an `&`.

**The build, in the job tree.** `@sveltejs/adapter-cloudflare` reads
`wrangler.jsonc` (`unstable_readConfig`) and writes the Worker to its `main`
and the static output to its `assets.directory`; the component's
`workerEntrypoint` and `assetsDir` name the same two paths for the lane's
`verify-build-output`, and `wrangler deploy --config wrangler.jsonc` reads
them back. All are relative to `apps/web`, so they hold in the staged tree
orun builds in (`.orun/runs/<exec>/<job>/work/apps/web`); the end-to-end
tier builds, dry-deploys and serves the site from such a tree.

**The site's CI is on from its first commit.** `ci.yml` plans nothing only
while `intent.yaml` names the placeholder `ws_CHANGE_ME`, which this
repository carries and no site does (the scaffold writes the site's
workspace, or `ws_SET_ME`, which fails loudly).

**Testing without the platform.** `testing/lib/bootstrap.sh` places every
phase and runs the blueprint's own `run:` hooks, read out of the document, so
the whole bootstrap short of the platform's typed actions runs in CI on every
pull request; `testing/e2e.test.sh` then builds, dry-deploys and serves what
it produced and runs the component's own smoke against it.
