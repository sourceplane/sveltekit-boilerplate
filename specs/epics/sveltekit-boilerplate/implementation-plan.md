# sveltekit-boilerplate — implementation plan

Milestones land in order; each task is one pull request on an
`orun/SK-n-<slug>` branch with an `Orun-Task: SK-n` trailer.

## SK0 — the spec ✅

This doc set, `epic.yaml` and the task contracts, merged to `main`.

**Done when**
- the five documents and `epic.yaml` are on `main`
- `tasks/SK-1..SK-3.TaskContract.yaml` exist (SK-4 joined with SK3)

## SK1 — the site on Workers ✅

`apps/web` is the upstream boilerplate on SvelteKit 3 with the Cloudflare
adapter, the beacon in the layout, the committed `wrangler.jsonc`, and a
server-render test.

**Done when**
- `pnpm install && pnpm typecheck && pnpm lint && pnpm test && pnpm build` is green locally and in `Checks`
- `wrangler dev --config wrangler.jsonc` answers `/` (200, "to your new SvelteKit app"), `/about` (200, no `<script>`), `/todos` (the server `load` runs against the demo API; a `userid` cookie is set), `/svelte-welcome.webp` and a `/_app/immutable/*` chunk (200), `/nope` (404)
- (SK3 replaced the demo API and the `userid` cookie: the todos now live in the visitor's own capped httpOnly `todos` cookie, `src/routes/todos/store.js` — risk SK-L)

## SK2 — ready to instantiate ✅

README (run, test, preview, deploy; the beacon token; what the todos demo
talks to), `IMPLEMENTATION-STATUS.md`, epic `completed`.

**Done when**
- the README quick start works from a fresh clone
- the status file lists every PR and departure

## SK3 — a baseline ✅

`blueprint.yaml`, `repo-blueprint.yaml`, `.baseline/` (identity, task
contracts, the site's README), `apps/web/src/lib/site.js` (the name seam),
`tooling/rebrand`, `tooling/bootstrap`, `hooks/render-deployment-docs.sh`,
`ai/context/`, `docs/phases/`, `BOOTSTRAP.md`, `testing/`, `baseline.yml`
and `tag.yml` (design §6), built the way portfolio-starter-kit's
`baseline-v2` is, with what its first live bootstrap taught already in.

**Done when**
- orun at the bootstrap floor (v2.58.11) and at the lane pin (v2.78.4) reads
  `repo-blueprint.yaml`, and `testing/manifest.test.sh` holds the card to it
- `Baseline CI` is green: the contract tests, the leak gate, the offline
  bootstrap (`testing/placement.test.sh`) and the end-to-end tier
  (`testing/e2e.test.sh`)
- the status file records what is proven offline and what only a live
  bootstrap can prove

## SK4 — one landing ✅

`repo-blueprint.yaml` builds the whole site in one landing, `01-product`,
and records it in `03-docs` (hooks only) — cirrus-baseline `baseline-v22`'s
shape, the port portfolio-starter-kit makes in PK-6: the brokered Cloudflare
secrets minted in `01-product`'s `post`, after the repository is created and
linked; `.baseline/tasks/01-product` in place of the scaffold and site
contracts; every bootstrap landing checked by `plan` alone (`ci.yml` skips
its lanes and `checks.yml` its job on `orun/BASE-…` branches); the offline
bootstrap and the e2e tier landing on an empty "Initial commit", as the
platform's first pull request does.

**Done when**
- `repo-blueprint.yaml` builds the site in `01-product` and records it in
  `03-docs`; the card's programme names the same two
- a bootstrap landing is checked by `plan` alone
- `Baseline CI` is green, and a site bootstrapped from the next tag is live
  on stage and prod (the live half is still open: `baseline-v2` is the
  first tag that carries SK4, and no site has been bootstrapped from it —
  risk SK-H)

## SK5 — the cirrus standard ✅

Bring the baseline to cirrus-baseline's standard, with nothing about the site
itself changing.

- **No kiox.** `kiox.yaml`/`kiox.lock` pinned an orun (v2.15.0) that nothing
  ran: every workflow installs orun itself through `orun-action` with its own
  `version:`. The files, their two modules and the rebrand's skip entry go.
- **Component docs.** `tooling/catalog/gen-component-docs.py` writes each
  component's `docs/overview.md`, `docs/architecture.md` and `docs/runbook.md`
  from what the component declares, as cirrus-baseline's do; the pages ship
  with the component. Baseline CI runs it with `--check`. The app's
  `prettier --check .` skips them (`apps/web/.prettierignore`).
- **The context pack.** `ai/context/current.md`, `decisions.md` and
  `open-risks.md` beside the two pages a site ships with — this
  repository's own, so no module places them.
- **Status that agrees with the tags.** SK3 is tagged `baseline-v1`; SK4 is
  merged (untagged until `baseline-v2`); the design and plan describe the
  cookie store SK3 built.
- **The subdomain from the Cloudflare connection (SK-7).** The card's
  `subdomain` input declares `from: connection.cloudflare.workersSubdomain`,
  as cirrus-baseline's does since baseline-v23: the bootstrap door fills it
  from the connection the build is bound to, so the console asks for nothing
  a typo could get wrong. `testing/manifest.test.sh` takes cirrus-baseline's
  rule, which requires the provider in `spec.requires.integrations`.

**Done when**
- `git grep -i kiox` finds nothing outside this milestone's own record
  (`specs/`, `tasks/`, `ai/context/`), and the leak gate and the offline
  bootstrap pass without the two modules
- the docs check is green in Baseline CI
- this file, the status file and `epic.yaml` agree

## After SK3 (outside this repository)

1. Cut `baseline-v1` with `tag.yml` from the merged `main`. ✅ Done (SK3).
2. Register the row in orun-cloud's `infra/baselines-registry/baselines.yaml`
   (unlisted) with the card vendored at the tag.
3. Bootstrap one site from the tag against a workspace; record its timings;
   then flip the row to public with a page on orunbase.com.

## Sequencing note

SK1 needs only SK0's contracts; SK2 is documentation over SK1's verified
build; SK3 packages SK1's site as a baseline. Deploying is the gated Orun
lane, not a milestone.
