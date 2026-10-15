import adapter from '@sveltejs/adapter-cloudflare';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';

// SvelteKit 3 is configured here (svelte.config.js is no longer read).
// adapter-auto (Vercel) becomes adapter-cloudflare: the build emits the Worker
// (.svelte-kit/cloudflare/_worker.js) with the static output beside it, and
// the committed wrangler.jsonc is the deployable config. The pre-1.0
// `methodOverride` option is gone — the todo forms target named actions.
// Vercel's web vitals (VERCEL_ANALYTICS_ID) became the Cloudflare Web
// Analytics beacon in src/routes/+layout.svelte.
export default defineConfig({
  plugins: [sveltekit({ adapter: adapter() })],
  test: {
    include: ['src/**/*.test.js'],
    environment: 'node'
  }
});
