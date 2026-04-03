<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'

const store = useSetupStore()
const c = store.config.cloudflare
</script>

<template>
  <div class="section">
    <h2 class="section-title">🌐 Cloudflare</h2>
    <div class="card">
      <h3 class="card-title">API Credentials</h3>
      <div class="grid">
        <PasswordInput v-model="c.apiToken" label="API Token (DNS Edit)" help-text="Must have Zone:DNS:Edit permissions." required />
        <PasswordInput v-model="c.apiKey" label="Global API Key" />
        <PasswordInput v-model="c.fullApiKey" label="Full API Key" />
        <TextInput v-model="c.apiEmail" label="API Email" type="email" />
      </div>
    </div>
    <div class="card">
      <h3 class="card-title">Account & Zone</h3>
      <div class="grid">
        <TextInput v-model="c.accountId" label="Account ID" />
        <TextInput v-model="c.zoneId" label="Zone ID" help-text="Required for DNS record management." />
      </div>
    </div>
    <div class="card">
      <h3 class="card-title">Zero Trust / Tunnel</h3>
      <div class="grid">
        <TextInput v-model="c.tunnelId" label="Tunnel ID" />
        <PasswordInput v-model="c.tunnelSecret" label="Tunnel Secret" />
        <TextInput v-model="c.connectorId" label="Connector ID" />
      </div>
    </div>
    <div class="card">
      <h3 class="card-title">Subdomain Routing</h3>
      <div class="grid">
        <TextInput v-model="c.subdomainServiceUrl" label="Subdomain Service URL" type="url" placeholder="https://example.com" />
        <TextInput v-model="c.subdomainBase" label="System Subdomain Base" placeholder="example.com" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.card { background: var(--bg-card); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; }
.card-title { font-size: 16px; font-weight: 600; color: var(--text-heading); margin-bottom: 16px; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; }
</style>
