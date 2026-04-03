<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import SelectInput from '@/components/fields/SelectInput.vue'

const store = useSetupStore()
const c = store.config.aws

const regionOptions = [
  { value: 'us-east-1', label: 'US East (N. Virginia)' },
  { value: 'us-east-2', label: 'US East (Ohio)' },
  { value: 'us-west-1', label: 'US West (N. California)' },
  { value: 'us-west-2', label: 'US West (Oregon)' },
  { value: 'ca-central-1', label: 'Canada (Central)' },
  { value: 'eu-west-1', label: 'EU (Ireland)' },
  { value: 'eu-central-1', label: 'EU (Frankfurt)' },
  { value: 'ap-southeast-1', label: 'Asia Pacific (Singapore)' },
]
</script>

<template>
  <div class="section">
    <h2 class="section-title">☁️ AWS</h2>
    <div class="grid">
      <TextInput v-model="c.accessKeyId" label="Access Key ID" placeholder="AKIA..." />
      <PasswordInput v-model="c.secretAccessKey" label="Secret Access Key" />
      <SelectInput v-model="c.region" label="Region" :options="regionOptions" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
