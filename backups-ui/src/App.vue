<template>
  <div class="backup-app">
    <div class="backup-header">
      <h1>Backup &amp; Restore</h1>
      <span class="domain-badge">{{ domain }}</span>
    </div>

    <nav class="tab-nav">
      <router-link :to="`/websites/${domain}/backups`">Backups</router-link>
      <router-link :to="`/websites/${domain}/backups/restores`">Restores</router-link>
      <router-link :to="`/websites/${domain}/backups/schedules`">Schedules</router-link>
    </nav>

    <router-view />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const domain = computed(() => (route.params.domain as string) || '')
</script>
