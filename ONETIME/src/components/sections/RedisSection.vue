<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'

const store = useSetupStore()
const c = store.config.redis
</script>

<template>
  <div class="section">
    <h2 class="section-title">📡 Redis & Channels</h2>
    <div class="grid">
      <TextInput v-model="c.host" label="Redis Host" placeholder="redis" help-text="Docker service name or hostname." />
      <NumberInput v-model="c.port" label="Redis Port" :min="1" :max="65535" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
