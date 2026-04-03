<script setup lang="ts">
import { ref } from 'vue'

defineProps<{
  modelValue: string
  label: string
  placeholder?: string
  helpText?: string
  required?: boolean
}>()

defineEmits<{ 'update:modelValue': [value: string] }>()

const visible = ref(false)
</script>

<template>
  <div class="field">
    <label class="field-label">
      {{ label }}
      <span v-if="required" class="required">*</span>
    </label>
    <div class="password-wrapper">
      <input
        :type="visible ? 'text' : 'password'"
        :value="modelValue"
        :placeholder="placeholder"
        class="field-input"
        @input="$emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      />
      <button type="button" class="toggle-btn" @click="visible = !visible">
        {{ visible ? '🙈' : '👁️' }}
      </button>
    </div>
    <p v-if="helpText" class="field-help">{{ helpText }}</p>
  </div>
</template>

<style scoped>
.field { margin-bottom: 16px; }
.field-label {
  display: block; font-size: 13px; font-weight: 600;
  color: var(--text-muted); margin-bottom: 6px;
  text-transform: uppercase; letter-spacing: 0.5px;
}
.required { color: var(--danger); }
.password-wrapper { position: relative; }
.field-input {
  width: 100%; padding: 10px 44px 10px 14px;
  background: var(--bg-input); border: 1px solid var(--border);
  border-radius: var(--radius); color: var(--text); font-size: 14px;
  transition: border-color 0.2s;
}
.field-input:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(59,130,246,0.15); }
.toggle-btn {
  position: absolute; right: 8px; top: 50%; transform: translateY(-50%);
  background: none; border: none; cursor: pointer; font-size: 16px; padding: 4px;
}
.field-help { font-size: 12px; color: var(--text-muted); margin-top: 4px; }
</style>
