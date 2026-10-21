# sveltekit-boilerplate — open risks

What is not yet proven or not yet decided. The full write-up of every risk,
including the accepted and resolved ones, is
`specs/epics/sveltekit-boilerplate/risks-and-open-questions.md`; this page
lists only what is still live, so it should be short.

| ID | Risk | State | What closes it |
|---|---|---|---|
| SK-H | No live bootstrap yet: the repository created and linked, the Cloudflare token minted, a real `wrangler deploy` and the probes are unproven. The one attempt (2026-10-15) never started — the platform's build sandbox failed to provision | OPEN | One bootstrap from a tag against a workspace |

Accepted, and worth knowing before you change them: SK-G (`nodejs_compat`
for the adapter's `nodejs_als`), SK-I (a custom domain is the owner's step).
Settled or noted: SK-E (tests inside the app), SK-F (formatting), SK-M (the
name seam and the app's prettier).
