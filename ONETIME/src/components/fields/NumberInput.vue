<script setup lang="ts">
defineProps<{
  modelValue: number
  label: string
  placeholder?: string
  helpText?: string
  min?: number
  max?: number
  step?: number
  required?: boolean
}>()

defineEmits<{ 'update:modelValue': [value: number] }>()
</script>

<template>
  <div class="field">
    <label class="field-label">
      {{ label }}
      <span v-if="required" class="required">*</span>
    </label>
    <input
      type="number"
      :value="modelValue"
      :placeholder="placeholder"
      :min="min"
      :max="max"
      :step="step || 1"
      class="field-input"
      @input="$emit('update:modelValue', Number(($event.target as HTMLInputElement).value))"
    />
    <p v-if="helpText" class="field-help">{{ helpText }}</p>
  </div>
</template>

<style scoped>
.field { margin-bottom: 16px; }
.field-label { display: block; font-size: 13px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
.required { color: var(--danger); }
.field-input {
  width: 100%; padding: 10px 14px; background: var(--bg-input);
  border: 1px solid var(--border); border-radius: var(--radius);
  color: var(--text); font-size: 14px; transition: border-color 0.2s;
}
.field-input:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(59,130,246,0.15); }
.field-help { font-size: 12px; color: var(--text-muted); margin-top: 4px; }
</style>
