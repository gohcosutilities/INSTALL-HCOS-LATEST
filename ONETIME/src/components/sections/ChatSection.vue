<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import NumberInput from '@/components/fields/NumberInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.chat
</script>

<template>
  <div class="section">
    <h2 class="section-title">💬 Chat</h2>
    <div class="grid">
      <ToggleSwitch v-model="c.showSeenStatus" label="Show Seen Status" help-text="Display read receipts." />
      <NumberInput v-model="c.maxMessageLength" label="Max Message Length" :min="100" :max="10000" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
