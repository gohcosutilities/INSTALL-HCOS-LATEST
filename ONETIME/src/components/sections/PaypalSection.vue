<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import SelectInput from '@/components/fields/SelectInput.vue'

const store = useSetupStore()
const c = store.config.paypal

const modeOptions = [
  { value: 'sandbox', label: 'Sandbox' },
  { value: 'live', label: 'Live' },
]
</script>

<template>
  <div class="section">
    <h2 class="section-title">💰 PayPal</h2>
    <div class="grid">
      <SelectInput v-model="c.mode" label="PayPal Mode" :options="modeOptions" />
      <TextInput v-model="c.testClientId" label="Test Client ID" />
      <PasswordInput v-model="c.testSecret" label="Test Secret" />
      <TextInput v-model="c.liveClientId" label="Live Client ID" />
      <PasswordInput v-model="c.liveSecret" label="Live Secret" />
      <TextInput v-model="c.webhookId" label="Webhook ID" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
