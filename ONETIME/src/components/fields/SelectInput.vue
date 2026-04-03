<script setup lang="ts">
defineProps<{
  modelValue: string
  label: string
  options: { value: string; label: string }[]
  helpText?: string
}>()

defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <div class="field">
    <label class="field-label">{{ label }}</label>
    <select
      :value="modelValue"
      class="field-select"
      @change="$emit('update:modelValue', ($event.target as HTMLSelectElement).value)"
    >
      <option v-for="opt in options" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
    </select>
    <p v-if="helpText" class="field-help">{{ helpText }}</p>
  </div>
</template>

<style scoped>
.field { margin-bottom: 16px; }
.field-label { display: block; font-size: 13px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
.field-select {
  width: 100%; padding: 10px 14px; background: var(--bg-input);
  border: 1px solid var(--border); border-radius: var(--radius);
  color: var(--text); font-size: 14px; cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%2394a3b8' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
}
.field-select:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(59,130,246,0.15); }
.field-help { font-size: 12px; color: var(--text-muted); margin-top: 4px; }
</style>
