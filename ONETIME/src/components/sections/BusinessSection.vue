<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'

const store = useSetupStore()
const c = store.config.business
</script>

<template>
  <div class="section">
    <h2 class="section-title">🏢 Business</h2>
    <div class="grid">
      <TextInput v-model="c.countryCode" label="Country Code" placeholder="US" help-text="ISO 3166-1 alpha-2." />
      <TextInput v-model="c.provinceState" label="Province / State" placeholder="NS" />
      <TextInput v-model="c.vatNumber" label="VAT Number" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
