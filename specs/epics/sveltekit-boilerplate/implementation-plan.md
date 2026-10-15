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

## SK2 — ready to instantiate ✅

README (run, test, preview, deploy; the beacon token; what the todos demo
talks to), `IMPLEMENTATION-STATUS.md`, epic `completed`.

**Done when**
- the README quick start works from a fresh clone
- the status file lists every PR and departure

## SK3 — a baseline

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

## After SK3 (outside this repository)

1. Cut `baseline-v1` with `tag.yml` from the merged `main`.
2. Register the row in orun-cloud's `infra/baselines-registry/baselines.yaml`
   (unlisted) with the card vendored at the tag.
3. Bootstrap one site from the tag against a workspace; record its timings;
   then flip the row to public with a page on orunbase.com.

## Sequencing note

SK1 needs only SK0's contracts; SK2 is documentation over SK1's verified
build; SK3 packages SK1's site as a baseline. Deploying is the gated Orun
lane, not a milestone.
