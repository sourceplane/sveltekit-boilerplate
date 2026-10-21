# web — architecture

Built by the turbo pipeline from `apps/web` and deployed with wrangler.

|                     |                                     |
| ------------------- | ----------------------------------- |
| Worker config       | `apps/web/wrangler.jsonc`           |
| Entry               | `.svelte-kit/cloudflare/_worker.js` |
| Compatibility date  | `2026-10-01`                        |
| Compatibility flags | `nodejs_compat`                     |

## Bindings

| Binding  | Kind          | Source                   |
| -------- | ------------- | ------------------------ |
| `ASSETS` | Static assets | `.svelte-kit/cloudflare` |
