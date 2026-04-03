<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.core
</script>

<template>
  <div class="section">
    <h2 class="section-title">⚙️ Core Django Settings</h2>
    <div class="grid">
      <PasswordInput v-model="c.secretKey" label="Django Secret Key" placeholder="Generate a random 50+ char string" help-text="Must be unique and secret in production." required />
      <ToggleSwitch v-model="c.debug" label="Debug Mode" warning="Never enable in production!" />
      <TextInput v-model="c.siteUrl" label="Site URL" type="url" placeholder="https://request.example.com" help-text="Base URL for the backend/admin." required />
      <TextInput v-model="c.siteDomain" label="Site Domain" type="url" placeholder="https://onedash.example.com" help-text="Primary dashboard domain." />
      <TextInput v-model="c.appName" label="Application Name" placeholder="CLOUDTOOLS" />
      <TextInput v-model="c.frontendUrl" label="Frontend URL" type="url" placeholder="https://onedash.example.com" help-text="URL used in email notification links." />
      <PasswordInput v-model="c.systemPin" label="System PIN" placeholder="6-digit PIN" help-text="Required to access system configuration in UI." />
      <NumberInput v-model="c.systemPinLength" label="PIN Code Length" :min="4" :max="10" />
      <ToggleSwitch v-model="c.disableDnsVerification" label="Disable DNS Verification" warning="Development only — never in production!" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
