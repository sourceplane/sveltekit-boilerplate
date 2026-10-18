# sveltekit-boilerplate — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a site built from it; the
two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's SvelteKit boilerplate (the welcome page and its counter, the about
page, the todos demo) on SvelteKit 3 and Svelte 5, deployed as one Cloudflare
Worker + Static Assets through SvelteKit's own Cloudflare adapter — no
OpenNext. The todos live in each visitor's own httpOnly cookie. Packaged as an
Orun baseline: `orun new --blueprint repo-blueprint.yaml` builds a new site in
its own repository and takes it to live on stage and prod in one landing
(`01-product`), then records what went live (`03-docs`).

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` (SK3, [#4](https://github.com/sourceplane/sveltekit-boilerplate/pull/4) — the three-phase shape: `01-scaffold`, `02-site`, `03-docs`) |
| On `main` since | SK4 — one landing ([#5](https://github.com/sourceplane/sveltekit-boilerplate/pull/5), `01-product` + `03-docs`); SK5 — the cirrus standard (no kiox, generated component docs, this context pack). Neither is tagged |
| Proven live | No. Everything short of the platform is proven offline in Baseline CI. The one console bootstrap attempted (2026-10-15, `bst_1G0YCW84`) never started: the platform's build sandbox failed to provision (risk SK-H). The card's 5 minutes is an estimate |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/sveltekit-boilerplate/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/sveltekit-boilerplate/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/sveltekit-boilerplate/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What the component is | `apps/web/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |

## Next

1. Cut `baseline-v2` with `tag.yml` from `main`, so the registry can pin the
   one-landing shape (SK4) and SK5.
2. Bootstrap one site from it against a workspace and record its timings in
   place of the estimate (closes SK-H).
