<template>
  <!-- Reusable Material Design Components -->
  
  <!-- Text Field Component -->
  <template v-if="component === 'TextField'">
    <div class="text-field-container">
      <label 
        :for="id" 
        class="text-field-label"
        :class="{ 'text-field-label--focused': isFocused, 'text-field-label--disabled': disabled }"
      >
        {{ label }}
        <span v-if="required" class="text-field-required">*</span>
      </label>
      
      <div class="text-field-input-wrapper" :class="inputWrapperClasses">
        <textarea
          v-if="type === 'textarea'"
          :id="id"
          :value="modelValue"
          @input="handleInput"
          @focus="handleFocus"
          @blur="handleBlur"
          :disabled="disabled"
          :placeholder="placeholder"
          :rows="rows"
          class="text-field-input text-field-input--textarea"
          :class="inputClasses"
        ></textarea>
        
        <input
          v-else
          :id="id"
          :type="type"
          :value="modelValue"
          @input="handleInput"
          @focus="handleFocus"
          @blur="handleBlur"
          :disabled="disabled"
          :placeholder="placeholder"
          class="text-field-input"
          :class="inputClasses"
        />
        
        <div v-if="hasError" class="text-field-error-icon">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
          </svg>
        </div>
      </div>
      
      <div v-if="supportingText || errorMessage" class="text-field-supporting-text" :class="supportingTextClasses">
        {{ errorMessage || supportingText }}
      </div>
    </div>
  </template>

  <!-- Dropdown Field Component -->
  <template v-else-if="component === 'DropdownField'">
    <div class="text-field-container">
      <label 
        :for="id" 
        class="text-field-label"
        :class="{ 'text-field-label--focused': isFocused, 'text-field-label--disabled': disabled || loading }"
      >
        {{ label }}
        <span v-if="required" class="text-field-required">*</span>
      </label>
      
      <div class="text-field-input-wrapper" :class="inputWrapperClasses">
        <select
          :id="id"
          :value="modelValue"
          @input="handleInput"
          @focus="handleFocus"
          @blur="handleBlur"
          :disabled="disabled || loading"
          class="text-field-select"
          :class="inputClasses"
        >
          <option v-if="placeholder" value="" disabled selected>{{ placeholder }}</option>
          <option 
            v-for="option in processedOptions" 
            :key="option.value" 
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>
        
        <div class="text-field-dropdown-arrow">
          <svg v-if="loading" class="w-5 h-5 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
          </svg>
        </div>
        
        <div v-if="hasError" class="text-field-error-icon">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
          </svg>
        </div>
      </div>
      
      <div v-if="supportingText || errorMessage" class="text-field-supporting-text" :class="supportingTextClasses">
        {{ errorMessage || supportingText }}
      </div>
    </div>
  </template>

  <!-- Button Component -->
  <template v-else-if="component === 'Button'">
    <button
      @click="handleClick"
      :disabled="disabled"
      :type="type"
      class="md-button"
      :class="buttonClasses"
    >
      <span class="md-button__content">
        <slot></slot>
      </span>
      <span class="md-button__state-layer"></span>
    </button>
  </template>

  <!-- Icon Button Component -->
  <template v-else-if="component === 'IconButton'">
    <button
      @click="handleClick"
      :disabled="disabled"
      :type="type"
      class="md-icon-button"
      :class="iconButtonClasses"
    >
      <span class="md-icon-button__content">
        <slot></slot>
      </span>
      <span class="md-icon-button__state-layer"></span>
    </button>
  </template>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  // Component type
  component: {
    type: String,
    required: true
  },
  
  // Common props
  id: {
    type: String,
    required: true
  },
  disabled: {
    type: Boolean,
    default: false
  },
  
  // TextField specific props
  modelValue: {
    type: [String, Number],
    default: ''
  },
  label: {
    type: String,
    required: true
  },
  type: {
    type: String,
    default: 'text'
  },
  placeholder: {
    type: String,
    default: ''
  },
  required: {
    type: Boolean,
    default: false
  },
  supportingText: {
    type: String,
    default: ''
  },
  errorMessage: {
    type: String,
    default: ''
  },
  rows: {
    type: Number,
    default: 4
  },
  
  // Dropdown specific props
  options: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  },
  
  // Button specific props
  variant: {
    type: String,
    default: 'filled', // filled, outlined, text
    validator: (value) => ['filled', 'outlined', 'text'].includes(value)
  },
  size: {
    type: String,
    default: 'medium', // small, medium, large
    validator: (value) => ['small', 'medium', 'large'].includes(value)
  },
  type: {
    type: String,
    default: 'button'
  }
})

const emit = defineEmits(['update:modelValue', 'click', 'focus', 'blur'])

const isFocused = ref(false)

// Computed properties
const hasError = computed(() => !!props.errorMessage)

const inputClasses = computed(() => {
  return {
    'text-field-input--focused': isFocused.value,
    'text-field-input--disabled': props.disabled,
    'text-field-input--error': hasError.value,
    'text-field-input--textarea': props.type === 'textarea'
  }
})

const inputWrapperClasses = computed(() => {
  return {
    'text-field-input-wrapper--focused': isFocused.value,
    'text-field-input-wrapper--disabled': props.disabled,
    'text-field-input-wrapper--error': hasError.value
  }
})

const supportingTextClasses = computed(() => {
  return {
    'text-field-supporting-text--error': hasError.value
  }
})

const processedOptions = computed(() => {
  return props.options.map(option => {
    if (typeof option === 'string') {
      return { value: option, label: option }
    }
    return option
  })
})

// Button classes
const buttonClasses = computed(() => {
  return [
    `md-button--${props.variant}`,
    `md-button--${props.size}`,
    {
      'md-button--disabled': props.disabled
    }
  ]
})

const iconButtonClasses = computed(() => {
  return [
    `md-icon-button--${props.variant}`,
    `md-icon-button--${props.size}`,
    {
      'md-icon-button--disabled': props.disabled
    }
  ]
})

// Event handlers
const handleInput = (event) => {
  emit('update:modelValue', event.target.value)
}

const handleFocus = (event) => {
  isFocused.value = true
  emit('focus', event)
}

const handleBlur = (event) => {
  isFocused.value = false
  emit('blur', event)
}

const handleClick = (event) => {
  emit('click', event)
}
</script>

<style scoped>
/* Text Field Styles */
.text-field-container {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-bottom: 16px;
}

.text-field-label {
  font-family: 'Roboto', sans-serif;
  font-size: 12px;
  font-weight: 500;
  line-height: 16px;
  letter-spacing: 0.4px;
  color: var(--md-sys-color-on-surface-variant);
  margin-left: 16px;
  transition: color 0.2s ease-in-out;
}

.text-field-label--focused {
  color: var(--md-sys-color-primary);
}

.text-field-label--disabled {
  color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.38, transparent);
}

.text-field-required {
  color: var(--md-sys-color-error);
  margin-left: 2px;
}

.text-field-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  background-color: var(--md-sys-color-surface-variant);
  border-radius: 4px 4px 0 0;
  border-bottom: 1px solid var(--md-sys-color-on-surface-variant);
  transition: all 0.2s ease-in-out;
}

.text-field-input-wrapper:hover:not(.text-field-input-wrapper--disabled) {
  background-color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.04, var(--md-sys-color-surface-variant));
}

.text-field-input-wrapper--focused {
  border-bottom-color: var(--md-sys-color-primary);
  border-bottom-width: 2px;
}

.text-field-input-wrapper--error {
  border-bottom-color: var(--md-sys-color-error);
}

.text-field-input-wrapper--disabled {
  background-color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.04, var(--md-sys-color-surface-variant));
  border-bottom-color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.12, transparent);
}

.text-field-input {
  width: 100%;
  padding: 16px;
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  line-height: 24px;
  letter-spacing: 0.5px;
  color: var(--md-sys-color-on-surface);
  background-color: transparent;
  border: none;
  outline: none;
  transition: all 0.2s ease-in-out;
}

.text-field-input::placeholder {
  color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.6, transparent);
}

.text-field-input--disabled {
  color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.38, transparent);
  cursor: not-allowed;
}

.text-field-input--error {
  color: var(--md-sys-color-error);
}

.text-field-input--textarea {
  resize: none;
  min-height: 100px;
  padding-top: 16px;
  padding-bottom: 16px;
}

.text-field-select {
  width: 100%;
  padding: 16px 48px 16px 16px;
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  line-height: 24px;
  letter-spacing: 0.5px;
  color: var(--md-sys-color-on-surface);
  background-color: transparent;
  border: none;
  outline: none;
  cursor: pointer;
  appearance: none;
  transition: all 0.2s ease-in-out;
}

.text-field-dropdown-arrow {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--md-sys-color-on-surface-variant);
  pointer-events: none;
  transition: color 0.2s ease-in-out;
}

.text-field-input-wrapper--focused .text-field-dropdown-arrow {
  color: var(--md-sys-color-primary);
}

.text-field-error-icon {
  position: absolute;
  right: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: var(--md-sys-color-error);
}

.text-field-supporting-text {
  font-family: 'Roboto', sans-serif;
  font-size: 12px;
  line-height: 16px;
  letter-spacing: 0.4px;
  color: var(--md-sys-color-on-surface-variant);
  margin-left: 16px;
}

.text-field-supporting-text--error {
  color: var(--md-sys-color-error);
}

/* Material Design Button Styles */
.md-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-family: 'Roboto', sans-serif;
  font-weight: 500;
  letter-spacing: 0.1px;
  border: none;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  overflow: hidden;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
}

.md-button__content {
  position: relative;
  z-index: 1;
}

.md-button__state-layer {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: currentColor;
  opacity: 0;
  transition: opacity 0.2s ease-in-out;
}

.md-button:hover .md-button__state-layer {
  opacity: 0.08;
}

.md-button:focus .md-button__state-layer {
  opacity: 0.12;
}

.md-button:active .md-button__state-layer {
  opacity: 0.16;
}

/* Filled Button Variant */
.md-button--filled {
  background-color: #f8f8f8; /* Light gray background */
  background-image: linear-gradient(to bottom, #f8f8f8, #f1f1f1); /* Subtle gradient */
  border: 1px solid #c6c6c6; /* Gray border */
  border-radius: 2px; /* Slightly rounded corners */
  color: #333; /* Dark text color */
  font-family: Arial, sans-serif;
  font-size: 13px;
  font-weight: bold;
  padding: 8px 16px; /* Padding inside the button */
  cursor: pointer; /* Pointer cursor on hover */
  box-shadow: 0 1px 1px rgba(0, 0, 0, 0.1); /* Subtle shadow */
  text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5); /* Light text shadow */
  outline: none; /* Remove outline on focus */
}

.md-button--filled:hover {
  background-color: #f0f0f0;
  background-image: linear-gradient(to bottom, #f0f0f0, #e6e6e6);
  border-color: #999;
}

.md-button--filled:active {
  background-color: #e6e6e6;
  background-image: linear-gradient(to bottom, #e6e6e6, #f0f0f0);
  border-color: #777;
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.2);
}

/* Outlined Button Variant */
.md-button--outlined {
  background-color: transparent;
  color: var(--md-sys-color-primary);
  border: 1px solid var(--md-sys-color-outline);
}

.md-button--outlined:hover {
  background-color: color-mix(in srgb, var(--md-sys-color-primary) 0.08, transparent);
}

/* Text Button Variant */
.md-button--text {
  background-color: transparent;
  color: var(--md-sys-color-primary);
  padding: 10px 12px;
}

.md-button--text:hover {
  background-color: color-mix(in srgb, var(--md-sys-color-primary) 0.08, transparent);
}

/* Button Sizes */
.md-button--small {
  padding: 8px 16px;
  font-size: 14px;
  line-height: 20px;
}

.md-button--medium {
  padding: 10px 24px;
  font-size: 14px;
  line-height: 20px;
}

.md-button--large {
  padding: 12px 32px;
  font-size: 16px;
  line-height: 24px;
}

/* Disabled State */
.md-button--disabled {
  background-color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.12, transparent);
  color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.38, transparent);
  box-shadow: none;
  cursor: not-allowed;
}

.md-button--outlined.md-button--disabled {
  border-color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.12, transparent);
}

/* Icon Button Styles */
.md-icon-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  font-family: 'Roboto', sans-serif;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.2s ease-in-out;
  overflow: hidden;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
}

.md-icon-button__content {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.md-icon-button__state-layer {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: currentColor;
  opacity: 0;
  transition: opacity 0.2s ease-in-out;
}

.md-icon-button:hover .md-icon-button__state-layer {
  opacity: 0.08;
}

.md-icon-button:focus .md-icon-button__state-layer {
  opacity: 0.12;
}

.md-icon-button:active .md-icon-button__state-layer {
  opacity: 0.16;
}

/* Icon Button Variants */
.md-icon-button--standard {
  background-color: transparent;
  color: var(--md-sys-color-on-surface-variant);
}

.md-icon-button--standard:hover {
  background-color: color-mix(in srgb, var(--md-sys-color-on-surface-variant) 0.08, transparent);
}

/* Icon Button Sizes */
.md-icon-button--small {
  width: 40px;
  height: 40px;
}

.md-icon-button--large {
  width: 56px;
  height: 56px;
}

/* Icon Button Disabled State */
.md-icon-button--disabled {
  background-color: transparent;
  color: color-mix(in srgb, var(--md-sys-color-on-surface) 0.38, transparent);
  cursor: not-allowed;
}

/* Focus styles for accessibility */
.md-button:focus-visible,
.md-icon-button:focus-visible {
  outline: 2px solid var(--md-sys-color-primary);
  outline-offset: 2px;
}

/* Reduced Motion */
@media (prefers-reduced-motion: reduce) {
  .md-button,
  .md-icon-button,
  .text-field-input,
  .text-field-select {
    transition: none;
  }
}
</style>