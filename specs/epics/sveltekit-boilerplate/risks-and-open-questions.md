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

## SK-B — The hosted demo API (RESOLVED in SK3 — see SK-L)

`/todos` talks to `https://api.svelte.dev`, an external service the
template does not own. On 2026-10-15 it answers `500 {"message":"Invalid
URL string."}` to every request, so `load` calls `error(500)` and the
page renders SvelteKit's 500 page — under `wrangler dev` here exactly as
it would on Vercel today. The hook, the `load`, the actions and the
cookie all run; the client is kept as written. Replacing the API with a
KV-backed store is the obvious follow-up for a real app, not this port.

SK3 settled it otherwise: the service turned out to be gone, not down, and a
baseline cannot ship a page that fails for every visitor, so the todos now
live in the visitor's own cookie (SK-L).

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

## SK-H — No live bootstrap yet (OPEN)

Everything short of the platform is proven on every pull request: the card
against the build, the blueprint read by the pinned orun, the leak gate, the
offline bootstrap with the blueprint's own hooks, the site's own plan for the
01-product merge, and the produced site built, dry-deployed, served and
smoke-tested from a staged job tree. What is NOT proven is the platform's
half — the repository created and linked, the Cloudflare token minted by
`integrations/reconcile`, a real `wrangler deploy`, the probes against
workers.dev. Hence the registry row is `unlisted` until one bootstrap from
the tag has come up, as portfolio-starter-kit's first tag was (its first
live bootstrap found two faults, carried here as SK-J and SK-K).

2026-10-15: the one console bootstrap attempted (workspace `sveltekit-live`,
`bst_1G0YCW84`) never started — the platform's cloud build sandbox failed to
provision. Nothing of this baseline ran, so it answers nothing here; SK-H
stays OPEN.

## SK-I — A custom domain is the owner's step (ACCEPTED)

Attaching a domain to a Worker needs zone-level permissions. The platform
brokers `workers-deploy` (Workers Scripts, KV, account read — no DNS) and
`dns-edit` only with zone ids, which a build does not have. Rather than ship a
parked component, the site's README says how to attach the domain. Unlike the
portfolio, nothing in the repository changes with it: the site builds no
absolute links, and SvelteKit's form actions check a request's `Origin`
against the host it arrived on.

## SK-J — The workspace install's layout in the job tree (RESOLVED by pin, measured)

portfolio-starter-kit's first live bootstrap (from its `baseline-v1`) died in
`build-app` on both deploy lanes: stack-tectonic 0.20.0 marks the workspace
install `scope: lane`, orun runs it once in the source checkout and stages
every job's tree with its top-level `node_modules` as a symlink out of the
tree, and Next 16's Turbopack refuses that. This baseline is built with the
fix already in: stack-tectonic **0.19.0**, where the job installs inside its
own staged tree, and an e2e tier that stages the job as orun does
(`testing/lib/stage-job.py`) with the install layout the pinned composition
plans.

Measured for this site (2026-10-15): with the pin at 0.20.0, the same e2e
tier is GREEN — Vite, the Cloudflare adapter, `wrangler deploy --dry-run` and
`wrangler dev` all work through the lane's symlinked `node_modules`. The pin
stays at 0.19.0 anyway: it is the layout the first live build proved, the
site has one job per lane (`lane: isolated`), so a shared install saves
nothing, and a bump is then a deliberate, tested step (`intent.yaml` says so).

## SK-K — The convergence watch reads the newest run on a commit (RESOLVED)

The same portfolio bootstrap's `converge` step reported green while the
deploy lanes had failed: `orun.run/watch@v1` with `sha:` takes the newest
workflow run for the merge commit from ANY workflow, and `checks.yml` also
ran on the push to main. Here `checks.yml` runs on pull requests and
`workflow_dispatch` only, so a push to main starts `ci.yml` alone, and
`testing/coverage.test.sh` fails if a shipped workflow other than `ci.yml`
runs on push.

## SK-L — Every site would have inherited the demo API (RESOLVED)

SK-B would have travelled: every site built from this baseline would have
rendered `/todos` against `api.svelte.dev`, and its nav would have linked a
page that fails from day one. The service is not down but gone — it answers
500 to `/todos/<id>` and 404 to `/` — which is why current SvelteKit
templates dropped the demo.

Resolved by storage that needs no third party: `src/routes/todos/store.js`
keeps each visitor's list in their own httpOnly cookie (`path=/todos`,
`SameSite=Lax`, the list as base64url-encoded JSON). The demo keeps its
point — a server `load` and named form actions (`create`, `update` for
toggle and edit, `delete`) that work without JavaScript, enhanced in place
by Kit's `enhance` when it is there. The `userid` cookie, its hook and the
`cookie` dependency went with the API: nothing else read them.

The cookie's 4 KB is the new limit, and it is enforced, not hoped for: 50
todos, 100 characters each (control characters stripped), and a change that
would push the encoded value past 3,800 bytes is refused with a message on
the page. A list is per browser — cleared with its cookies, invisible to
the server between requests, not shared across devices; a KV namespace
behind `store.js`'s `read`/`write` is the step for a site that needs more.
The e2e tier requires `/todos` to answer 200 and drives a todo through all
four actions, reading each back with the cookie; the deployment record
probes `/todos` again.

## SK-M — The name seam and the app's prettier (SETTLED)

`apps/web` lints with `prettier --check .` and `singleQuote: true`; the
rename writes the site's name with `JSON.stringify` (double quotes) so that
a name with an apostrophe stays a valid string. The seam's one line carries
`// prettier-ignore`, so the site's own `lint` passes under any name. The
e2e tier runs the site's Checks after the rename with "Sam's Notes & Links".
