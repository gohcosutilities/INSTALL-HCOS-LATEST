<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import SelectInput from '@/components/fields/SelectInput.vue'

const store = useSetupStore()
const c = store.config.celery

const resultOptions = [
  { value: 'django-db', label: 'Django DB' },
  { value: 'redis', label: 'Redis' },
]
</script>

<template>
  <div class="section">
    <h2 class="section-title">⏱️ Celery</h2>
    <div class="grid">
      <TextInput v-model="c.brokerUrl" label="Broker URL" placeholder="redis://redis:6379/0" help-text="Supports redis:// and rediss:// (SSL)." />
      <SelectInput v-model="c.resultBackend" label="Result Backend" :options="resultOptions" />
      <PasswordInput v-model="c.upstashUrl" label="Upstash Redis URL" help-text="Optional cloud Redis for production." />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
