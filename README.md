# sveltekit-boilerplate

Vercel's [SvelteKit boilerplate](https://github.com/vercel/examples/tree/main/framework-boilerplates/sveltekit)
— a welcome page with a counter, a static about page, and a todos demo
(server `load`, form actions that work without JavaScript, a per-visitor
cookie set in a server hook, a hosted demo API) — running on **Cloudflare
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
  --set reponame=acme-notes --set productname="Acme Notes" --set productdomain=acme.dev \
  --set githuborg=acme-inc --set subdomain=<workers-dev-subdomain>
```

Or, once the platform's registry lists it, from the Orun console (Baselines →
`sveltekit-boilerplate` → Build). Three phases — `01-scaffold` (the repository,
its CI and identity), `02-site` (the site deployed to stage and prod,
smoke-tested), `03-docs` (the live deployment recorded) — each landing one
pull request in the new repository. **[BOOTSTRAP.md](BOOTSTRAP.md)** is the
operator guide; [docs/phases/](docs/phases/README.md) has a page per phase.

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
| The `userid` cookie hook, the counter, the header | `apps/web/src/hooks.server.js`, `apps/web/src/lib` |
| The demo-API client (`https://api.svelte.dev`) | `apps/web/src/routes/todos/api.js` |
| Layout with the optional analytics beacon | `apps/web/src/routes/+layout.svelte`, `apps/web/src/env.js` |
| Adapter, Worker config, deploy contract | `apps/web/vite.config.js`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Tests (`svelte/server` renders: the counter, the site's name on its pages) | `apps/web/src/lib/Counter.test.js`, `apps/web/src/lib/site.test.js` |

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

The todos page talks to `api.svelte.dev`, the hosted demo store the
template ships with; it is not part of this repository and its availability
is Svelte's, not yours (at the time of writing it answers 500 to every
request, and the page shows SvelteKit's error page). Point `api.js` at a
store you own — a KV namespace is the natural one here — to make it yours.

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
| `checks.yml` | install, wire fixtures, typecheck, lint, test, build — every PR (not pushes: on main, `ci.yml` must be the only run a commit has, because the bootstrap's convergence watch takes the newest one) | yes |
| `ci.yml` | the Orun pipeline: `orun plan --changed`, then one job per lane; deploys stage → prod on merge. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does | yes |
| `baseline.yml` | the baseline's own tiers: contract tests, the blueprint read by the pinned orun, the leak gate, the offline bootstrap, the site built, dry-deployed and served | no |
| `tag.yml` | cuts a `baseline-vN` tag (manual) | no |
