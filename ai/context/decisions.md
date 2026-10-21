# sveltekit-boilerplate — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | SvelteKit's own Cloudflare adapter (`@sveltejs/adapter-cloudflare`), not OpenNext; the component deploys the Worker and assets it emits | SvelteKit is not Next; the adapter is the framework's | `specs/epics/sveltekit-boilerplate/design.md` §2 |
| 2 | SvelteKit 3 + adapter 8 (Svelte 5, Vite 8), the components left in Svelte 3 syntax | The current adapter needs Kit 3; Svelte 5 runs the old syntax in legacy mode | risks SK-A, SK-C, design.md §2 |
| 3 | Kit's named actions and `$app/forms` `enhance` replace the pre-1.0 action protocol; `form.js` goes | The method override and the hand-rolled `enhance` no longer exist in Kit | design.md §2 |
| 4 | The Cloudflare Web Analytics beacon replaces `web-vitals` and `VERCEL_ANALYTICS_ID` | Rendered only when `PUBLIC_CF_BEACON_TOKEN` is set at build | IMPLEMENTATION-STATUS (SK1) |
| 5 | Tests live in `apps/web` | Svelte components compile only through the app's Svelte Vite plugin | risk SK-E |
| 6 | The todos live in the visitor's own httpOnly cookie, capped (50 × 100 characters, 3,800 encoded bytes); the hook, the `userid` cookie and `cookie` go. Supersedes "the demo API stays as written" | `api.svelte.dev` is gone; a nav link to a failing page cannot ship | risks SK-B, SK-L |
| 7 | `apps/web/wrangler.jsonc` is committed as written, not rendered | The Worker binds only `ASSETS`: there is nothing to wire | IMPLEMENTATION-STATUS (SK1), design.md §3 |
| 8 | The site's name is one seam, `src/lib/site.js` | The rename rewrites one line, written so that any name stays a valid string | IMPLEMENTATION-STATUS (SK3), risk SK-M |
| 9 | One landing (`01-product`) then the record (`03-docs`); every bootstrap landing is checked by `plan` alone. Supersedes `baseline-v1`'s three phases | A landing has a fixed cost; the convergence on `main` builds and tests the site anyway | IMPLEMENTATION-STATUS (SK4) |
| 10 | `ci.yml` plans nothing while `intent.yaml` names `ws_CHANGE_ME`; `checks.yml` runs on pull requests only, and not on `orun/BASE-…` branches | A bootstrap cannot set a repository variable (replaced the `ORUN_CI` gate); the convergence watch takes the newest run on a commit from any workflow | risk SK-K, IMPLEMENTATION-STATUS (SK3, SK4) |
| 11 | stack-tectonic 0.19.0, though 0.20.0 was measured green for this site | The layout the first live build proved; one job per lane gains nothing from a shared install | risk SK-J |
| 12 | orun is pinned only where it runs (the `orun-action` `version:` in each workflow); no kiox. Component docs are generated from the manifests and checked in CI | `kiox.yaml` pinned a version nothing ran; a hand-written copy of a manifest drifts silently | IMPLEMENTATION-STATUS (SK5), `tooling/catalog/gen-component-docs.py` |
| 13 | The workers.dev subdomain is read from the Cloudflare connection (`from: connection.cloudflare.workersSubdomain`), not asked; only a hand-run build passes `--set subdomain` | It belongs to the account like its id and has one right answer; a typed one could only be wrong, and wrong showed up after deploy in the smoke and the probes (cirrus-baseline since baseline-v23) | IMPLEMENTATION-STATUS (SK-7) |
