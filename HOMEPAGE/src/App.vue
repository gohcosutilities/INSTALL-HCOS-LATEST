<template>

  <RouterView />
  <ChatWidget />
</template>

<script setup lang="ts">
import { RouterView } from 'vue-router'
import ChatWidget from '@/components/ChatWidget.vue';
</script>