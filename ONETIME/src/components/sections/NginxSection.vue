<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'

const store = useSetupStore()
const c = store.config.nginx
</script>

<template>
  <div class="section">
    <h2 class="section-title">🌍 Nginx</h2>
    <div class="grid">
      <TextInput v-model="c.templatePath" label="Template Path" />
      <TextInput v-model="c.containerName" label="Container Name" placeholder="nginx_main" />
      <TextInput v-model="c.sslCertPath" label="SSL Certificate Path" />
      <TextInput v-model="c.sslKeyPath" label="SSL Key Path" />
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 20px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--bg-card); padding: 20px; border-radius: var(--radius); border: 1px solid var(--border); }
</style>
