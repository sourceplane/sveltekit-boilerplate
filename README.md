# sveltekit-boilerplate

Vercel's [SvelteKit boilerplate](https://github.com/vercel/examples/tree/main/framework-boilerplates/sveltekit)
— a welcome page with a counter, a static about page, and a todos demo
(server `load`, form actions that work without JavaScript, the list kept in
the visitor's own cookie) — running on **Cloudflare
Workers + Static Assets** through SvelteKit's own
[`@sveltejs/adapter-cloudflare`](https://svelte.dev/docs/kit/adapter-cloudflare),
and packaged as an **Orun baseline**: one command takes a new site from
nothing to live on stage and prod, in its own repository, under its own name.

Swapping the Vercel adapter for the Cloudflare one is the port; the three
years from `1.0.0-next` to SvelteKit 3 are the rest of the diff, and every
move is recorded. What the baseline adds is everything needed to make a copy
of it somebody else's — built the way
[cirrus-baseline](https://github.com/sourceplane/cirrus-baseline) is. See
[`specs/epics/sveltekit-boilerplate`](specs/epics/sveltekit-boilerplate/README.md)
for the design, the milestones and the as-built status.

## Instantiating a site

```bash
git clone --depth 1 --branch <baseline-tag> https://github.com/sourceplane/sveltekit-boilerplate
cd sveltekit-boilerplate
orun new --blueprint repo-blueprint.yaml --out ~/sites/acme-notes --run-hooks --resume \
  --set reponame=acme-notes --set productname="Acme Notes" \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`sveltekit-boilerplate` → Build). Two phases — `01-product` (the repository
created, then the whole site in one pull request, deployed to stage and prod
and smoke-tested) and `03-docs` (the live deployment recorded) — each landing
one pull request in the new repository. **[BOOTSTRAP.md](BOOTSTRAP.md)** is
the operator guide; [docs/phases/](docs/phases/README.md) has a page per
phase.

The new repository receives the **site only** — the app and its tests, its
CI, its tooling, a README of its own and its operating contract — renamed
throughout to the site's name, repository and Cloudflare Worker. None of this
repository's machinery ships.

| What makes it a baseline | Where |
|---|---|
| The console card (inputs, secrets, programme) | `blueprint.yaml` |
| The build document (modules, phases, hooks) | `repo-blueprint.yaml` |
| This tree's identity, and the bootstrap's task contracts | `.baseline/` |
| The rename engine | `tooling/rebrand/rebrand.mjs` |
| The bootstrap's helpers (deferrals, redeploy marker, work-tree strip) | `tooling/bootstrap/` |
| The deployment-record renderer | `hooks/render-deployment-docs.sh` |
| The site's README and context pack | `.baseline/product/README.md`, `ai/context/` |
| The baseline's tests: contract, leak, offline bootstrap, end to end | `testing/`, `.github/workflows/baseline.yml` |
| Cutting a `baseline-vN` tag | `.github/workflows/tag.yml` |

## What is here (the site)

| Surface | Where |
|---|---|
| The site's name (the home page's heading, every page's `<title>`) | `apps/web/src/lib/site.js` |
| `/` (pre-rendered, with the counter), `/about` (pre-rendered, no JavaScript), `/todos` (server `load` + `create`/`update`/`delete` actions) | `apps/web/src/routes` |
| The counter, the header | `apps/web/src/lib` |
| The todos store: the visitor's list in one httpOnly cookie | `apps/web/src/routes/todos/store.js` |
| Layout with the optional analytics beacon | `apps/web/src/routes/+layout.svelte`, `apps/web/src/env.js` |
| Adapter, Worker config, deploy contract | `apps/web/vite.config.js`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Tests (`svelte/server` renders: the counter, the site's name on its pages; the todos store and actions) | `apps/web/src/lib/*.test.js`, `apps/web/src/routes/todos/store.test.js` |

## Getting started

```bash
pnpm install          # runs `svelte-kit sync`
pnpm typecheck        # svelte-check
pnpm lint             # prettier --check
pnpm test             # vitest
pnpm build            # vite build → apps/web/.svelte-kit/cloudflare (_worker.js + the static output)
```

```bash
pnpm --filter @app/web dev        # http://localhost:5173
pnpm --filter @app/web preview    # wrangler dev over the built Worker
```

Optional: `PUBLIC_CF_BEACON_TOKEN` at build time renders the Cloudflare Web
Analytics beacon (stands in for the template's Vercel web vitals).

The todos keep each visitor's list in their own browser: one httpOnly
cookie, scoped to `/todos`, holding the list as JSON (base64url-encoded),
capped at 50 todos of up to 100 characters and refused past ~3.8 KB so it
stays under a browser's 4 KB cookie limit. The template's hosted demo store,
`api.svelte.dev`, is gone (it answers 500 or 404 to everything), and a
cookie needs no third party while keeping the demo's point: a server `load`
and form actions that work without JavaScript. To share a list across
devices, swap `store.js`'s `read`/`write` for a KV namespace.

## How it maps to Vercel

| Vercel | Here |
|---|---|
| `@sveltejs/adapter-auto` (→ `adapter-vercel`) | `@sveltejs/adapter-cloudflare`: Worker at `.svelte-kit/cloudflare/_worker.js`, static output beside it |
| `web-vitals` → Vercel analytics (`VERCEL_ANALYTICS_ID`) | Cloudflare Web Analytics beacon, opt-in by token |
| `vercel.json` output directory | `wrangler.jsonc` `assets.directory` |
| Pre-rendered `/` and `/about` on the CDN | Served by Static Assets ahead of the Worker |
| Deploy on push | Orun deploys `<repo>-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`) |
| "Deploy with Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a site |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a site carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the site built and dry-deployed per environment; they do not typecheck, lint or run the tests), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does. A manual run (Orunbase's Deploy button, or Run workflow on `main`) plans the environment and components it names under the push-to-main trigger, so they deploy as a merge deploys them | yes |
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the site installed, type-checked, linted, tested, built, dry-deployed and served (`testing/e2e.test.sh`, before every tag) | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |
