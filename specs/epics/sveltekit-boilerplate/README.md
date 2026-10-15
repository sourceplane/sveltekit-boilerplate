# Epic: sveltekit-boilerplate (SK)

**Vercel's SvelteKit boilerplate is the `create-svelte` demo of its day: a welcome page with a spring-animated counter, a static about page, and a todos page that exercises what a framework adapter must do — a server `load`, form actions that work without JavaScript, a cookie set in a server hook, a call to a hosted API. On Cloudflare the adapter is SvelteKit's own. Swapping `adapter-auto` for `adapter-cloudflare` is the port; what the three years since `1.0.0-next.428` demand is the rest — named actions for the removed method override, Kit's `enhance` for the hand-rolled one, `$app/state` for `$app/stores`, `#lib` for `$lib`, the configuration in `vite.config.js`. What the repository adds is the Cirrus baseline shape around it: an Orun intent, a component that deploys the adapter's Worker and assets, a credential-free checks lane, and an Orun lane that turns on when the product is linked.**

This is the third port without OpenNext, on the shape astro-boilerplate set for frameworks with a native Cloudflare adapter: the `cloudflare-workers-assets-turbo` component takes the Worker entrypoint plus the assets directory the adapter emits.

## Status

| Field | Value |
|-------|-------|
| Status | Draft |
| Cluster | **SK** (SK0–SK2) |
| Owner(s) | `apps/web` (the site, with its server-render test) |
| Builds on | `cirrus-baseline` conventions; the `astro-boilerplate` port's repository shape |
| Upstream | [vercel/examples `framework-boilerplates/sveltekit`](https://github.com/vercel/examples/tree/main/framework-boilerplates/sveltekit) |
| Changes | Adapter swap, SvelteKit 1.0-next → 3 (Svelte 5, Vite 8), the Cloudflare Web Analytics beacon in the layout for Vercel's web vitals; the pages, the counter, the header, the hook and the demo-API client keep their code |
| Decisions locked | (1) SvelteKit's Cloudflare adapter, not OpenNext (SvelteKit is not Next). (2) SvelteKit 3 + adapter 8 (current majors; the current adapter needs Kit 3). (3) Kit's own `enhance` and named actions replace the pre-1.0 action protocol — the template's `form.js` goes. (4) Cloudflare Web Analytics for `web-vitals` + `VERCEL_ANALYTICS_ID`. (5) Tests live in the app (`svelte/server` rendering needs the Svelte Vite plugin). (6) The demo API (`api.svelte.dev`) stays as written — an external service, not a Vercel primitive. |
| Gate | SK1 is the first user-visible rung. |
| Shipped as | |

## Read order

1. `design.md` — what maps to what, the build, what is out of scope
2. `implementation-plan.md` — the milestones and what "done" means for each
3. `risks-and-open-questions.md` — what could go wrong and what was decided
4. `IMPLEMENTATION-STATUS.md` — what actually shipped (kept distinct from intent)

## Milestones at a glance

| Milestone | What it lands | Done when |
|---|---|---|
| SK0 — the spec | this doc set and the task contracts | merged on `main` |
| SK1 — the site on Workers | `apps/web` on SvelteKit 3 with the Cloudflare adapter, a test, green checks | `wrangler dev` serves the three pages, the assets and a 404; Checks green |
| SK2 — ready to instantiate | README, as-built status | a reader can run, test, preview and deploy it |
