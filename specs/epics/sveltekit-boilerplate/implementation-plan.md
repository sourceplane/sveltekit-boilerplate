# sveltekit-boilerplate — implementation plan

Milestones land in order; each task is one pull request on an
`orun/SK-n-<slug>` branch with an `Orun-Task: SK-n` trailer.

## SK0 — the spec ✅

This doc set, `epic.yaml` and the task contracts, merged to `main`.

**Done when**
- the five documents and `epic.yaml` are on `main`
- `tasks/SK-1..SK-3.TaskContract.yaml` exist

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

## Sequencing note

SK1 needs only SK0's contracts; SK2 is documentation over SK1's verified
build. Deploying is the gated Orun lane, not a milestone.
