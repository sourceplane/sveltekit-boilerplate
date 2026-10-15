import { defineEnvVars } from '@sveltejs/kit/env';

// Cloudflare Web Analytics stands in for Vercel's web vitals: one beacon
// script in src/routes/+layout.svelte, rendered only when
// PUBLIC_CF_BEACON_TOKEN is set at build time (Cloudflare dashboard → Web
// Analytics → add a site). Unset → empty → no script.
export const variables = defineEnvVars({
  PUBLIC_CF_BEACON_TOKEN: {
    description: 'Cloudflare Web Analytics beacon token; unset renders no beacon',
    public: true,
    static: true,
    schema: (value) => value ?? ''
  }
});
