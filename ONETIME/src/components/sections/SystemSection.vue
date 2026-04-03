<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import TagInput from '@/components/fields/TagInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'

const store = useSetupStore()
const c = store.config.system
</script>

<template>
  <div class="section">
    <h2 class="section-title">🖥️ System / Tenant</h2>
    <div class="grid">
      <TextInput v-model="c.mainHostname" label="Main Hostname" placeholder="onedash.example.com" />
      <TextInput v-model="c.alternateHostname" label="Alternate Hostname" />
      <TextInput v-model="c.mainIpAddress" label="Main IP Address" help-text="Empty triggers DNS lookup." />
      <TagInput v-model="c.allDomains" label="All System Domains" placeholder="example.com" />
      <ToggleSwitch v-model="c.useSystemIpForTenantDns" label="Use System IP for Tenant DNS" />
      <TextInput v-model="c.developmentIp" label="Development IP" />
      <TextInput v-model="c.productionIp" label="Production IP" />
      <TextInput v-model="c.productionHostname" label="Production Hostname" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
