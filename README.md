# sveltekit-boilerplate

Vercel's [SvelteKit boilerplate](https://github.com/vercel/examples/tree/main/framework-boilerplates/sveltekit)
— a welcome page with a counter, a static about page, and a todos demo
(server `load`, form actions that work without JavaScript, a per-visitor
cookie set in a server hook, a hosted demo API) — running on **Cloudflare
Workers + Static Assets** through SvelteKit's own
[`@sveltejs/adapter-cloudflare`](https://svelte.dev/docs/kit/adapter-cloudflare),
inside the repository conventions of the
[Cirrus baseline](https://github.com/sourceplane/cirrus-baseline).

Swapping the Vercel adapter for the Cloudflare one is the port; the three
years from `1.0.0-next` to SvelteKit 3 are the rest of the diff, and every
move is recorded. See
[`specs/epics/sveltekit-boilerplate`](specs/epics/sveltekit-boilerplate/README.md)
for the design, the milestones and the as-built status.

## What is here

| Surface | Where |
|---|---|
| `/` (pre-rendered, with the counter), `/about` (pre-rendered, no JavaScript), `/todos` (server `load` + `create`/`update`/`delete` actions) | `apps/web/src/routes` |
| The `userid` cookie hook, the counter, the header | `apps/web/src/hooks.server.js`, `apps/web/src/lib` |
| The demo-API client (`https://api.svelte.dev`) | `apps/web/src/routes/todos/api.js` |
| Layout with the optional analytics beacon | `apps/web/src/routes/+layout.svelte`, `apps/web/src/env.js` |
| Adapter, Worker config, deploy contract | `apps/web/vite.config.js`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Test (`svelte/server` render) | `apps/web/src/lib/Counter.test.js` |

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
| Deploy on push | Orun deploys `sveltekit-boilerplate-web-{stage,prod}` on merge to `main` |

## Deploying

`.github/workflows/checks.yml` runs install, typecheck, lint, test and build
on every push and pull request. `ci.yml` is the Orun pipeline: set
`execution.state.workspace` in `intent.yaml` to this product's workspace
(`orun cloud link`), connect a Cloudflare account to it, and set the
`ORUN_CI` repository variable to `true`. A merge to `main` then deploys the
Worker to `stage`, then `prod`.
