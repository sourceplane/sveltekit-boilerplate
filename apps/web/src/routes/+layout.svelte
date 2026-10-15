<script>
  import Header from '#lib/header/Header.svelte';
  import { PUBLIC_CF_BEACON_TOKEN } from '$app/env/public';
  import '../app.css';
</script>

<svelte:head>
  {#if PUBLIC_CF_BEACON_TOKEN}
    <script
      defer
      src="https://static.cloudflareinsights.com/beacon.min.js"
      data-cf-beacon={JSON.stringify({ token: PUBLIC_CF_BEACON_TOKEN })}
    ></script>
  {/if}
</svelte:head>

<Header />

<main>
  <slot />
</main>

<footer>
  <p>visit <a href="https://kit.svelte.dev">kit.svelte.dev</a> to learn SvelteKit</p>
</footer>

<style>
  main {
    flex: 1;
    display: flex;
    flex-direction: column;
    padding: 1rem;
    width: 100%;
    max-width: 1024px;
    margin: 0 auto;
    box-sizing: border-box;
  }

  footer {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    padding: 40px;
  }

  footer a {
    font-weight: bold;
  }

  @media (min-width: 480px) {
    footer {
      padding: 40px 0;
    }
  }
</style>
