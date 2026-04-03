<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import NumberInput from '@/components/fields/NumberInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.helpdesk
</script>

<template>
  <div class="section">
    <h2 class="section-title">🎫 Helpdesk</h2>
    <div class="grid">
      <ToggleSwitch v-model="c.escalationEnabled" label="Escalation Enabled" />
      <NumberInput v-model="c.escalationDays" label="Escalation Days" :min="1" />
      <NumberInput v-model="c.escalationMinutes" label="Escalation Minutes" :min="1" />
      <NumberInput v-model="c.onHoldEscalationMinutes" label="On-Hold Escalation Minutes" :min="1" />
      <ToggleSwitch v-model="c.autoCloseEnabled" label="Auto-Close Enabled" />
      <NumberInput v-model="c.autoCloseDays" label="Auto-Close Days" :min="1" />
      <ToggleSwitch v-model="c.includeStaffInitialFollowup" label="Include Staff in Initial Follow-up" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
