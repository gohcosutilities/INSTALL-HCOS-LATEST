<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import NumberInput from '@/components/fields/NumberInput.vue'
import ToggleSwitch from '@/components/fields/ToggleSwitch.vue'
import SelectInput from '@/components/fields/SelectInput.vue'

const store = useSetupStore()
const c = store.config.email

const backendOptions = [
  { value: 'django.core.mail.backends.smtp.EmailBackend', label: 'SMTP' },
  { value: 'django.core.mail.backends.console.EmailBackend', label: 'Console (dev)' },
]
</script>

<template>
  <div class="section">
    <h2 class="section-title">📧 Email Configuration</h2>
    <div class="grid">
      <SelectInput v-model="c.backend" label="Email Backend" :options="backendOptions" />
      <TextInput v-model="c.host" label="SMTP Host" placeholder="smtp.gmail.com" />
      <NumberInput v-model="c.port" label="SMTP Port" :min="1" :max="65535" />
      <ToggleSwitch v-model="c.useTls" label="Use TLS" />
      <ToggleSwitch v-model="c.useSsl" label="Use SSL" help-text="Mutually exclusive with TLS." />
      <TextInput v-model="c.username" label="SMTP Username" placeholder="user@gmail.com" />
      <PasswordInput v-model="c.password" label="SMTP Password" />
      <TextInput v-model="c.fromEmail" label="Default From Email" type="email" placeholder="noreply@example.com" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
