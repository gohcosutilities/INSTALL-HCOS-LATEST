<script setup lang="ts">
import { ref } from 'vue'

defineProps<{
  modelValue: string[]
  label: string
  placeholder?: string
  helpText?: string
}>()

const emit = defineEmits<{ 'update:modelValue': [value: string[]] }>()
const newTag = ref('')

function addTag(tags: string[]) {
  const val = newTag.value.trim()
  if (val && !tags.includes(val)) {
    emit('update:modelValue', [...tags, val])
  }
  newTag.value = ''
}

function removeTag(tags: string[], index: number) {
  const copy = [...tags]
  copy.splice(index, 1)
  emit('update:modelValue', copy)
}
</script>

<template>
  <div class="field">
    <label class="field-label">{{ label }}</label>
    <div class="tag-container">
      <span v-for="(tag, i) in modelValue" :key="i" class="tag">
        {{ tag }}
        <button type="button" class="tag-remove" @click="removeTag(modelValue, i)">×</button>
      </span>
      <input
        v-model="newTag"
        :placeholder="placeholder || 'Type and press Enter'"
        class="tag-input"
        @keydown.enter.prevent="addTag(modelValue)"
      />
    </div>
    <p v-if="helpText" class="field-help">{{ helpText }}</p>
  </div>
</template>

<style scoped>
.field { margin-bottom: 16px; }
.field-label { display: block; font-size: 13px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
.tag-container {
  display: flex; flex-wrap: wrap; gap: 6px; padding: 8px;
  background: var(--bg-input); border: 1px solid var(--border);
  border-radius: var(--radius); min-height: 44px; align-items: center;
}
.tag-container:focus-within { border-color: var(--primary); box-shadow: 0 0 0 3px rgba(59,130,246,0.15); }
.tag {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; background: var(--primary); color: white;
  border-radius: 12px; font-size: 12px; font-weight: 500;
}
.tag-remove {
  background: none; border: none; color: white; cursor: pointer;
  font-size: 14px; padding: 0 2px; opacity: 0.7;
}
.tag-remove:hover { opacity: 1; }
.tag-input {
  flex: 1; min-width: 120px; border: none; background: transparent;
  color: var(--text); font-size: 14px; outline: none;
}
.field-help { font-size: 12px; color: var(--text-muted); margin-top: 4px; }
</style>
