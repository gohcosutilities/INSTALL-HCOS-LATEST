<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TagInput from '@/components/fields/TagInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'

const store = useSetupStore()
const c = store.config.security
</script>

<template>
  <div class="section">
    <h2 class="section-title">🛡️ Security, CORS & Allowed Hosts</h2>
    <div class="card">
      <TagInput v-model="c.allowedDomains" label="Allowed Domains" placeholder="e.g., example.com" help-text="Root domains for multi-domain support." />
      <TagInput v-model="c.corsOrigins" label="CORS Allowed Origins" placeholder="https://onedash.example.com" help-text="Full origin URLs including https://." />
      <TagInput v-model="c.allowedHosts" label="Additional Allowed Hosts" placeholder="api.example.com" help-text="Hosts allowed beyond the defaults." />
      <NumberInput v-model="c.sessionCookieAge" label="Session Cookie Age (seconds)" :min="300" help-text="Default 86400 = 24 hours." />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.card { background: var(--bg-card); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; }
</style>
