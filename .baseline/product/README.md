# sveltekit-boilerplate

A SvelteKit site — a welcome page with a counter, a static about page, and a
todos demo (a server `load` and form actions that work without JavaScript,
the list kept in the visitor's own cookie) — on **Cloudflare Workers + Static
Assets** through SvelteKit's own
[`@sveltejs/adapter-cloudflare`](https://svelte.dev/docs/kit/adapter-cloudflare).

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the site uses into
[ai/context/deployment.md](ai/context/deployment.md); how the site deploys
and how to operate it is in
[ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The site's name (the home page's heading, every page's `<title>`) | `apps/web/src/lib/site.js` |
| `/` (pre-rendered, with the counter), `/about` (pre-rendered, no JavaScript), `/todos` (server `load` + `create`/`update`/`delete` actions) | `apps/web/src/routes` |
| The counter, the header | `apps/web/src/lib` |
| The todos store: the visitor's list in one httpOnly cookie | `apps/web/src/routes/todos/store.js` |
| Layout with the optional analytics beacon | `apps/web/src/routes/+layout.svelte`, `apps/web/src/env.js` |
| Workers build and deploy contract | `apps/web/vite.config.js`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Tests (`svelte/server` renders: the counter, the site's name on its pages; the todos store and actions) | `apps/web/src/**/*.test.js` (vitest) |

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

Make the site yours in `apps/web/src/routes` (the pages) and
`apps/web/src/lib/site.js` (its name).

One optional build-time variable (`apps/web/.env.example`):

| Variable | What it does |
|---|---|
| `PUBLIC_CF_BEACON_TOKEN` | Cloudflare Web Analytics token (dashboard → Web Analytics → add a site). Unset, no script is rendered. |

The todos page keeps each visitor's list in their own browser: one httpOnly
cookie, scoped to `/todos`, holding the list as JSON — no database and no
third party, and every action works without JavaScript. A cookie holds about
4 KB, so the list is capped (50 todos of up to 100 characters, and a change
that would not fit is refused with a message). To share a list across
devices, swap `read` and `write` in `apps/web/src/routes/todos/store.js` for
a KV namespace bound in `apps/web/wrangler.jsonc`.

## How it deploys

Merges to `main` converge through Orun: `.github/workflows/ci.yml` plans the
changed components and runs each lane against the workspace in
`intent.yaml`. The site deploys to `stage`, then to `prod` once stage has
converged on the same commit; `dev` only verifies. The Worker is
`sveltekit-boilerplate-web-<env>` on your account's workers.dev subdomain, and
every deploy is smoke-tested over HTTP. A pull request runs the same
pipeline's verify lanes: the site built and dry-deployed for each
environment, with nothing deployed. They do not lint or run the tests, so
run `pnpm typecheck`, `pnpm lint` and `pnpm test` before you push. (A push
to `main` builds, deploys and smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The
Cloudflare token and account id are brokered per run from the workspace's
Cloudflare connection; nothing provider-shaped is stored in the repository
or in GitHub.

**Deploy by hand.** Orunbase's **Deploy** button on a component, or **Run
workflow** on the CI workflow in GitHub's Actions tab (on `main`), runs
`ci.yml` for the environment and components you pick, and each one deploys
exactly as a merge would deploy it. Leave the component blank to redeploy
every component in that environment, with nothing changed: after rotating a
secret, say. A component with nothing to run in that environment (a test
suite in `prod`) is left out with a notice.

## Custom domain

The site answers on workers.dev from its first deploy. To serve it on your
own domain, add the domain to the Cloudflare account the site deploys into
and attach it to the Worker (dashboard → Workers & Pages →
`sveltekit-boilerplate-web-prod` → Settings → Domains & Routes → Add → Custom
domain). Do the same for stage with a subdomain if you want one.

Nothing else has to change: the site builds no absolute links, so it answers
on whatever origin serves it, and SvelteKit's form actions check a request's
`Origin` against the host it arrived on. The repository names the domain in
one place, `BASE_DOMAIN` in `intent.yaml` (dev, stage and prod), which the
site was born with as the reserved placeholder
`sveltekit-boilerplate.example.com`. Replace it with your domain in the same
change that records it.
