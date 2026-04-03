<template>
  <button
    :class="buttonClasses"
    :disabled="disabled"
    v-bind="$attrs"
    @click="shouldNavigate(to)"
  >
    <slot></slot>
  </button>
</template>

<script setup>
import { computed } from 'vue';
import { navigateTo } from '@/services/navigate';
// Define component props with defaults
const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'secondary','amazon','main-ui','add-cart'].includes(value),
  },
  to: {
    type: String,
    default: undefined,
  },
  size: {
    type: String,
    default: 'medium',
    validator: (value) => ['small', 'medium', 'large'].includes(value),
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  pill: {
    type: Boolean,
    default: false,
  },
  block: {
    type: Boolean,
    default: false,
  }
});

// Compute the dynamic classes for the button
const buttonClasses = computed(() => [
  'hcos-button',
  `variant-${props.variant}`,
  `size-${props.size}`,
  { 
    'is-pill': props.pill,
    'is-block': props.block
  },
]);

const shouldNavigate = (to) => {
  if (to) {
    navigateTo(to);
  }
};

</script>

<style scoped>
/* --- CSS Variables for Easy Theming --- */

.hcos-button {
    display: inline-block;
    padding: 0;
    margin: 0;
    /* border-width: 0.15rem; */
    border-style: solid;
    border-radius: var(--amz-border-radius);
    font-family: var(--amz-font-family);
    font-weight: 400;
    text-align: center;
    vertical-align: middle;
    cursor: pointer;
    user-select: none;
    text-decoration: none;
    white-space: nowrap;
    box-shadow: 0 1px 2px rgb(179, 180, 180);
    transition: all 0.1s linear;
}
  
.size-medium {
  font-size: 14px;
  padding: 8px 15px;
  line-height: 1.5;
}
.size-large {
  font-size: 16px;
  padding: 12px 20px;
}

/* --- Modifier Styles --- */
.is-pill {
  border-radius: 9999px;
}

.is-block {
  display: block;
  width: 100%;
}


/* --- State Styles --- */
.hcos-button:active {
  transform: translateY(1px);
  box-shadow: 0 0 0 transparent;
  border-color: #555; /* A darker border on press for feedback */
}

.hcos-button:disabled {
  background: #f7f7f7;
  border-color: #e0e0e0;
  color: #a7a7a7;
  cursor: not-allowed;
  box-shadow: none;
  transform: none;
}

.variant-add-cart {
    background: #fff;
    color: #3c4043;
    border: 1px solid #dadce0;
    border-radius: 8px;
    padding: 0.5rem 1.0rem;
    font-weight: 500;
    font-size: 1rem;
    box-shadow: none;
    transition: background 0.2s, box-shadow 0.2s, border-color 0.2s;
    cursor: pointer;
}
.variant-add-cart:hover {
    background: transparent;
  border-color:  #f68702;
}

</style>