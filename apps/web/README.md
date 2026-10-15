# apps/web — the site

Vercel's [SvelteKit boilerplate](https://github.com/vercel/examples/tree/main/framework-boilerplates/sveltekit)
(the `create-svelte` demo app, MIT) on SvelteKit 3, running on Cloudflare Workers +
Static Assets through [`@sveltejs/adapter-cloudflare`](https://svelte.dev/docs/kit/adapter-cloudflare):

- `/` — the welcome page with the spring-animated counter, pre-rendered
- `/about` — pre-rendered, and ships no JavaScript
- `/todos` — a server `load` and form actions (`?/create`, `?/update`, `?/delete`)
  that work without JavaScript, the visitor's list kept in their own httpOnly
  cookie (`src/routes/todos/store.js`: JSON, capped to stay under 4 KB)
- Cloudflare Web Analytics (set `PUBLIC_CF_BEACON_TOKEN` at build time)

The site's name — the home page's heading and every page's `<title>` — is in
`src/lib/site.js`.

```bash
pnpm dev        # vite dev on http://localhost:5173
pnpm build      # vite build → .svelte-kit/cloudflare (_worker.js + the static output)
pnpm preview    # wrangler dev over the built Worker
pnpm test       # vitest
```

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
