<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'

const store = useSetupStore()
const c = store.config.invoicing
</script>

<template>
  <div class="section">
    <h2 class="section-title">🧾 Invoicing & Billing</h2>
    <div class="grid">
      <TextInput v-model="c.prefix" label="Invoice Prefix" placeholder="INV-" />
      <NumberInput v-model="c.numberStart" label="Invoice Number Start" :min="1" />
      <NumberInput v-model="c.defaultDueDays" label="Default Due Days" :min="1" />
      <NumberInput v-model="c.dueDays" label="Invoice Due Days" :min="1" />
      <NumberInput v-model="c.minimumHourlyBalance" label="Minimum Hourly Balance ($)" :min="0" :step="0.5" help-text="Required for hourly-billed services." />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
