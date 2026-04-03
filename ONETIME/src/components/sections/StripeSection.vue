<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.stripe
</script>

<template>
  <div class="section">
    <h2 class="section-title">💳 Stripe</h2>
    <div class="card">
      <ToggleSwitch v-model="c.liveMode" label="Live Mode" warning="Warning: Live mode processes real payments!" />
    </div>
    <div class="card">
      <h3 class="card-title">Test Keys</h3>
      <div class="grid">
        <TextInput v-model="c.testPublicKey" label="Test Public Key" placeholder="pk_test_..." />
        <PasswordInput v-model="c.testSecretKey" label="Test Secret Key" placeholder="sk_test_..." />
        <TextInput v-model="c.connectTestClientId" label="Connect Test Client ID" placeholder="ca_..." />
      </div>
    </div>
    <div class="card">
      <h3 class="card-title">Live Keys</h3>
      <div class="grid">
        <TextInput v-model="c.livePublicKey" label="Live Public Key" placeholder="pk_live_..." />
        <PasswordInput v-model="c.liveSecretKey" label="Live Secret Key" placeholder="sk_live_..." />
        <TextInput v-model="c.connectLiveClientId" label="Connect Live Client ID" placeholder="ca_..." />
      </div>
    </div>
    <div class="card">
      <h3 class="card-title">Platform</h3>
      <div class="grid">
        <TextInput v-model="c.systemAccountId" label="System Stripe Account ID" placeholder="acct_..." />
        <PasswordInput v-model="c.webhookSecret" label="Webhook Secret" placeholder="whsec_..." />
        <NumberInput v-model="c.applicationFee" label="Application Fee (cents)" :min="0" help-text="Platform fee for Stripe Connect." />
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
