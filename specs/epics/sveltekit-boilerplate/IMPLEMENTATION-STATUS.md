# sveltekit-boilerplate (SK) — Implementation status

As-built ≠ intent. This file records what actually shipped, and every place
the code departed from `design.md` or from the upstream template.

| Milestone | State | PR |
|---|---|---|
| SK0 — the spec | ✅ Shipped | [#1](https://github.com/sourceplane/sveltekit-boilerplate/pull/1) |
| SK1 — the site on Workers | ✅ Shipped | [#2](https://github.com/sourceplane/sveltekit-boilerplate/pull/2) |
| SK2 — ready to instantiate | ✅ Shipped | [#3](https://github.com/sourceplane/sveltekit-boilerplate/pull/3) |
| SK3 — a baseline | ✅ Shipped | [#4](https://github.com/sourceplane/sveltekit-boilerplate/pull/4) (SK-4), tagged `baseline-v1` |
| SK4 — one landing | ✅ Shipped (offline-proven; not yet bootstrapped live, risk SK-H) | [#5](https://github.com/sourceplane/sveltekit-boilerplate/pull/5) (SK-5) — on `main`, not yet tagged |
| SK5 — the cirrus standard | ✅ Shipped | SK-6 — on `main` after `baseline-v1`, not yet tagged |

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
`@sveltejs/kit/hooks`, body unchanged; the hook was deleted in SK3, below); `$lib/…` → `#lib/…` (`package.json`
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
types, and 2.x (what Kit 3 itself depends on) renamed the functions. (SK1–SK2:
SK3 removed the hook and the `cookie` dependency with the demo API — below.)

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

### The site's name comes from `src/lib/site.js` (SK3)

`SITE_NAME` (the upstream's own "SvelteKit app", from the home page's
heading) is the home page's heading tail and `<title>`, and the about and
todos pages' titles read `About | …` and `Todos | …` through `pageTitle`
(upstream: `Home`, `About`, `Todos`). It is the seam the baseline's rename
rewrites. `src/lib/site.test.js` renders the pages and reads the name back.

### The todos live in the visitor's cookie (SK3)

`api.svelte.dev` is gone (500 on `/todos/<id>`, 404 on `/`), so every site
would have shipped a nav link to a page that fails. `src/routes/todos/api.js`
is replaced by `store.js`: the list in one httpOnly cookie (`path=/todos`,
`SameSite=Lax`), JSON rows `[uid, text, done]` base64url-encoded, capped at 50
todos of 100 characters and refused past 3,800 encoded bytes. `load` and the
`create`/`update`/`delete` actions read and write it; the page shows an
action's `form.error`. `src/hooks.server.js` (the `userid` cookie), the
`App.Locals.userid` type and the `cookie` dependency are gone: nothing needs
them. `src/routes/todos/store.test.js` covers the round trip, the caps and
the four actions.

### `apps/web/README.md` is the app's, not the template's (SK3)

The upstream README advertised "Deploy with Vercel" and a Vercel demo, and it
ships into every site. It now describes the app and credits the template
(MIT).

## Departures from the port (SK3)

| What | Before | After | Why |
|---|---|---|---|
| `/todos` store | `api.svelte.dev` (gone), keyed by the hook's `userid` cookie | the visitor's own `todos` cookie; no hook, no `cookie` dependency | a page that fails for every visitor of every site cannot ship (risks SK-L) |
| `apps/web` smoke | `grep 'SvelteKit app'` on `/` | the nav's `/todos` link on `/`, and SvelteKit's 404 page for an unknown path | the name is the owner's, and HTML-escaped when it carries `&`; the 404 proves the Worker, not just the assets |
| `ci.yml` gate | `vars.ORUN_CI == 'true'` | skip only while `intent.yaml` names `ws_CHANGE_ME` | a bootstrap cannot set a repository variable |
| `checks.yml` | every push and pull request | pull requests and `workflow_dispatch` | one workflow per push to main (risks SK-K) |
| stack-tectonic | 0.18.2 | 0.19.0 | first-deploy retry (0.19.0); not 0.20.0's lane-scoped install (risks SK-J) |
| orun lane pin | v2.78.0 | v2.78.4 | cirrus-baseline's pin |
| `intent.yaml` | terraform `parameterDefaults`; docs pages under `specs/` | neither; docs pages `ai/context/*` | no terraform component; the pages must exist in a site |
| discovery roots | `apps/` only on disk | `infra/`, `packages/`, `tests/` carry a `.gitkeep` | `orun validate` and `orun plan` fail on a missing root ("failed to access discovery root infra") |
| `tasks/SK-1..3` | no `metadata` | `metadata.name` and `title` | `orun work check` (≥ v2.79) refuses them |

## One landing (SK4)

cirrus-baseline's baseline-v22 builds its whole product in one landing
(`01-product`) and checks each bootstrap pull request with `plan` alone. This
baseline now does the same (SK-5), the port portfolio-starter-kit makes in PK-6:

| Before (baseline-v1) | Now | Why |
|---|---|---|
| three phases: `01-scaffold`, `02-site`, `03-docs` | two: `01-product` (every module), `03-docs` (hooks only; its name kept, the gap kept, as Cirrus kept `08-docs`) | a landing has a fixed cost (place, PR, checks, merge, convergence start); nothing in the scaffold/site split was order the plan could not carry |
| `01-scaffold` waited on Checks (install, wire fixtures, typecheck, lint, test, build) and `plan`; `02-site` merged without waiting (`wait: false`); `03-docs` waited on both | every landing waits on its PR's CI, which on `orun/BASE-…` is `plan` alone: `ci.yml` skips the lanes and `checks.yml` now skips its job | the convergence on main installs, builds, deploys and smoke-tests the site for real, and this baseline's own CI runs the Checks over a bootstrapped tree at the tag being built (e2e); Checks on the PR was the same build twice, and most of each landing's wait |
| the brokered secrets minted in `02-site`'s `pre` | minted in `01-product`'s `post`, after `repo` and `link`, before `land` | the repository exists and is linked before a secret is written for its project — Cirrus's order |
| `02-site` seeded the lockfile from the baseline's, then pruned | `pnpm install --lockfile-only` only confirms the placed lockfile | the whole tree is placed at once, so the complete lockfile is already the right one |
| `.baseline/tasks/01-scaffold`, `02-site` | `.baseline/tasks/01-product` (`affects: [web]` — the retouch set; the site's tests run inside it) | one landing, one task |
| the offline bootstrap committed one landing per phase from an empty repository | the repository's empty first commit, then one per phase | on the platform the first pull request opens against an empty "Initial commit" by `orun`; it is the base the one landing's push is planned against (`testing/placement.test.sh` §4, `testing/e2e.test.sh` §2) |
| e2e ran the Checks at the scaffold's landing and at the finished site | at the finished site only | there is no scaffold landing, and no landing waits on Checks |

Not measured: this baseline has not been bootstrapped live yet. The one
console bootstrap attempted, on 2026-10-15 (workspace `sveltekit-live`,
`bst_1G0YCW84`), never started — the platform's cloud build sandbox failed
to provision ("Provisioning failed: daytona POST sandbox: 400 from
provider"), a platform capacity failure, not this baseline's. The estimate
here is 5 minutes (4 + 1), unmeasured; the sibling site baselines measured
7m07s–8m43s from the console on the three-landing shape. It is to be
replaced by the first bootstrap from `baseline-v2` (risks SK-H).

## The cirrus standard (SK5)

Nothing about the site changed. What changed is the baseline around it:

| What | Before | After | Why |
|---|---|---|---|
| orun pin | `kiox.yaml` (v2.15.0) + `kiox.lock`, shipped to every site | gone; orun is pinned where it runs, the `orun-action` `version:` in each workflow | nothing ran the kiox pin, and it disagreed with the lanes (v2.78.4) |
| `root-kiox`, `root-kiox-lock` modules | in `01-product` | removed (`testing/phases.test.sh`, the rebrand's skip list and `docs/phases/01-product.md` follow) | a site is placed with 62 files (61 − 2 + 3): no kiox, plus the docs below |
| component docs | none | `apps/web/docs/` — `overview.md`, `architecture.md`, `runbook.md` | cirrus-baseline documents every component; the workspace Docs library renders `docs/` beside each `component.yaml` |
| `apps/web/.prettierignore` | build output, caches, lockfiles | plus `/docs` | the app's `lint` is `prettier --check .`, which failed the site's Checks on the generated pages (tables written unpadded); they are checked against the manifest instead, and `pnpm format` must not rewrite them |
| how the docs stay true | — | `tooling/catalog/gen-component-docs.py` derives them from the manifest, the Worker config and package scripts; Baseline CI runs it with `--check` | a hand-written copy of a manifest drifts silently |
| context pack | `operations.md`, `deployment.md` | plus `current.md`, `decisions.md`, `open-risks.md` | cirrus-baseline's shape; the three new pages are this repository's own and no module places them (the leak gate still allows exactly two) |
| status | SK4 "in progress, this PR, to be tagged `baseline-v2`"; `design.md` naming the deleted `src/hooks.server.js` and `cookie` as kept; the plan's SK1 naming the demo API, and no SK4 section | SK4 shipped ([#5](https://github.com/sourceplane/sveltekit-boilerplate/pull/5)), on `main`, untagged (`baseline-v1` is SK3); the hook and the demo API marked as replaced by the cookie store (SK-L); an SK4 section in the plan | the documents had not caught up with the merge and with SK3 |

## Verified (SK5)

Over the whole of `main` as it now stands — SK4's one landing included,
which had no "Verified" section of its own:

- `testing/{manifest,phases,coverage,rebrand,retouch,bootstrap-defer}.test.sh`
  green; `gen-component-docs.py --check` green (1 component, 3 pages).
- `testing/leak.test.sh` at v2.58.11 (the blueprint job's pin): 62 files
  derived (61 − 2 kiox + 3 docs pages); `ai/context` still exactly the two
  declared pages; none of the 16 factory paths ships or is named, the
  generated pages included.
- `testing/placement.test.sh` at v2.58.11: 62 files placed; the two phases
  (`01-product`, `03-docs`) landed over an empty initial commit, the site
  branded, re-tenanted, gates restored, record rendered; the site's own plan deploys
  `web` to stage and prod side by side; `--resume` a no-op.
- `pnpm install --frozen-lockfile`, `wire:fixture` (no diff), typecheck
  (`svelte-check`: 0 errors, the template's 3 warnings), lint (`prettier
  --check .`), test (3 files, 11 tests), build green.
- `testing/e2e.test.sh` at v2.78.4 (the product job's pin) green: the
  finished site passes the Checks sequence — which first FAILED on the
  generated pages under `prettier --check .`, hence `/docs` in
  `apps/web/.prettierignore`; the stage lane's steps in the staged job tree;
  `wrangler dev` serves the built Worker, the component's smoke passes, and
  `/todos` creates, toggles, edits and deletes through the visitor's cookie.
- `orun task check SK-6` complete.

## Verified (SK3)

- `orun new --status` reads the blueprint at v2.58.11 (the bootstrap floor),
  v2.78.4 (the lane pin) and v2.79.0; `orun validate` passes.
- `testing/{manifest,phases,coverage,rebrand,retouch,bootstrap-defer}.test.sh`
  green; `orun work check` clean.
- `testing/leak.test.sh` (v2.58.11 and v2.79.0): 61 files derived; nothing of
  the factory, nothing local or built; no provenance prose.
- `testing/placement.test.sh` (v2.58.11 and v2.79.0; fixture "Sam's Notes &
  Links" / `acme-inc/acme-sveltekit`): three landings; rebrand `--verify`
  clean; workspace re-tenanted, `work:` stripped, promotion and dev lanes
  restored; deployment record rendered; no file in the site names the
  factory's paths; the site's own `orun plan` for the 02-site merge deploys
  `web` to stage and prod side by side with the site's Worker name, smoke and
  secret refs; `--resume` changes nothing.
- `testing/e2e.test.sh` (v2.78.4 and v2.79.0): the scaffold's landing and the
  finished site pass the Checks sequence; the stage lane's
  `install-workspace-dependencies`, `build-app`, `verify-build-output` and
  `deploy-dry-run` pass in a staged job tree; `wrangler dev` serves the built
  Worker from it; the component's own smoke passes; `/` (heading and title
  carry the escaped name), its `_app/immutable` chunks, the static files,
  `/about` (no `<script>`), `/todos` (200; a todo created with a plain form
  post, toggled through `enhance`, edited, and deleted through `enhance`,
  each read back by a GET carrying the httpOnly `todos` cookie) and a 404
  are the site's own. Re-run with the pin at 0.20.0 (lane layout): also green
  (risks SK-J).
- Not verified: a live bootstrap against a workspace (risks SK-H).

## Verified (SK1–SK2)

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
| @fontsource/fira-mono | ^4.5.0 | as upstream |
| vitest | ^5.0.4 | current; runs on the app's `vite.config.js` |
| wrangler | ^4.151.0 | compatibility_date 2026-10-01 |
