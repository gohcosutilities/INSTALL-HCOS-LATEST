<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.keycloak
</script>

<template>
  <div class="section">
    <h2 class="section-title">🔐 Keycloak / Authentication</h2>

    <div class="card">
      <h3 class="card-title">Server</h3>
      <div class="grid">
        <ToggleSwitch v-model="c.enabled" label="Keycloak Enabled" />
        <TextInput v-model="c.serverUrl" label="Server URL" type="url" placeholder="https://key.example.com" help-text="Internal server URL." required />
        <TextInput v-model="c.publicUrl" label="Public URL" type="url" placeholder="https://key.example.com" help-text="Browser-facing URL." />
        <TextInput v-model="c.realmName" label="Realm Name" placeholder="master" />
      </div>
    </div>

    <div class="card">
      <h3 class="card-title">Client Credentials</h3>
      <div class="grid">
        <TextInput v-model="c.clientId" label="Client ID" placeholder="hcos-backend" />
        <PasswordInput v-model="c.clientSecret" label="Client Secret" required />
        <TextInput v-model="c.frontendClientId" label="Frontend Client ID" placeholder="hcos-frontend" />
        <TextInput v-model="c.registrationClientId" label="Registration Client ID" placeholder="hcos-backend" />
        <PasswordInput v-model="c.registrationClientSecret" label="Registration Client Secret" />
      </div>
    </div>

    <div class="card">
      <h3 class="card-title">Admin Credentials</h3>
      <div class="grid">
        <TextInput v-model="c.adminUsername" label="Admin Username" placeholder="admin" />
        <PasswordInput v-model="c.adminPassword" label="Admin Password" required />
        <TextInput v-model="c.adminClientId" label="Admin Client ID" placeholder="hcos-backend" />
      </div>
    </div>

    <div class="card">
      <h3 class="card-title">SSO / OIDC</h3>
      <div class="grid">
        <TextInput v-model="c.ssoClientId" label="SSO Client ID" />
        <PasswordInput v-model="c.ssoClientSecret" label="SSO Client Secret" />
        <TextInput v-model="c.ssoDiscoveryUri" label="SSO Discovery URI" type="url" placeholder="https://key.example.com/realms/master/.well-known/openid-configuration" />
        <TextInput v-model="c.authFrontendClient" label="Auth Frontend Client" placeholder="hcos-frontend" />
      </div>
    </div>

    <div class="card">
      <h3 class="card-title">Sync & JWT</h3>
      <div class="grid">
        <NumberInput v-model="c.jwtLeeway" label="JWT Clock Skew Leeway (secs)" :min="0" :max="60" />
        <ToggleSwitch v-model="c.autoSyncPermissions" label="Auto-Sync Permissions" />
        <ToggleSwitch v-model="c.syncPermissions" label="Sync Permissions to Keycloak" />
        <ToggleSwitch v-model="c.syncAsync" label="Async Sync (via Celery)" help-text="Faster logins; requires Celery worker." />
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
