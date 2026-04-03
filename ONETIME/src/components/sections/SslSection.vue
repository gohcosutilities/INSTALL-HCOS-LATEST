<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.ssl
</script>

<template>
  <div class="section">
    <h2 class="section-title">🔒 SSL / Certbot</h2>
    <div class="grid">
      <ToggleSwitch v-model="c.wildcardEnabled" label="Wildcard SSL Enabled" help-text="Uses *.domain cert for all subdomains." />
      <TextInput v-model="c.letsencryptEmail" label="Let's Encrypt Email" type="email" placeholder="admin@example.com" required />
      <TextInput v-model="c.certbotConfDir" label="Certbot Config Directory" placeholder="/etc/letsencrypt" />
      <TextInput v-model="c.wildcardDomainPath" label="Wildcard Domain Path" placeholder="wildcard.example.com" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
