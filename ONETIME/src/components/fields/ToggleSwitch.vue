<script setup lang="ts">
defineProps<{
  modelValue: boolean
  label: string
  helpText?: string
  warning?: string
}>()

defineEmits<{ 'update:modelValue': [value: boolean] }>()
</script>

<template>
  <div class="field toggle-field">
    <div class="toggle-row">
      <label class="field-label">{{ label }}</label>
      <button
        type="button"
        class="toggle"
        :class="{ active: modelValue }"
        @click="$emit('update:modelValue', !modelValue)"
      >
        <span class="toggle-knob" />
      </button>
    </div>
    <p v-if="warning && modelValue" class="field-warning">⚠️ {{ warning }}</p>
    <p v-if="helpText" class="field-help">{{ helpText }}</p>
  </div>
</template>

<style scoped>
.field { margin-bottom: 16px; }
.toggle-field .field-label { margin-bottom: 0; }
.toggle-row { display: flex; align-items: center; justify-content: space-between; }
.field-label { font-size: 13px; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
.toggle {
  position: relative; width: 48px; height: 26px; border-radius: 13px;
  background: var(--border); border: none; cursor: pointer; transition: background 0.2s;
}
.toggle.active { background: var(--primary); }
.toggle-knob {
  position: absolute; top: 3px; left: 3px; width: 20px; height: 20px;
  border-radius: 50%; background: white; transition: transform 0.2s;
}
.toggle.active .toggle-knob { transform: translateX(22px); }
.field-warning { font-size: 12px; color: var(--warning); margin-top: 4px; }
.field-help { font-size: 12px; color: var(--text-muted); margin-top: 4px; }
</style>
