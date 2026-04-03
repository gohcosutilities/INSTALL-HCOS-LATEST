<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import NumberInput from '@/components/fields/NumberInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.policies
</script>

<template>
  <div class="section">
    <h2 class="section-title">📋 Service Policies</h2>
    <div class="grid">
      <ToggleSwitch v-model="c.suspendForNonPayment" label="Suspend for Non-Payment" />
      <NumberInput v-model="c.daysBeforeSuspension" label="Days Before Suspension" :min="1" />
      <ToggleSwitch v-model="c.usersCanEditAddress" label="Users Can Edit Address" />
      <ToggleSwitch v-model="c.fraudDetectionEnabled" label="Fraud Detection Enabled" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
