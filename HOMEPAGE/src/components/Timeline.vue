<script setup lang="ts">
import { computed } from 'vue';

interface Step {
  id: string;
  name: string;
  status: 'current' | 'complete' | 'upcoming';
}

const props = defineProps<{
  steps: Step[];
  currentStep: string;
  canAccessStep?: (stepId: string) => boolean;
}>();

const emit = defineEmits(['go-to-step']);

// Determine if a step button should be clickable
const isStepClickable = (step: Step) => {
  // Current step is not clickable (already there)
  if (step.id === props.currentStep) return false;
  
  // Completed steps are always clickable (can go back)
  if (step.status === 'complete') return true;
  
  // Check if upcoming step can be accessed
  if (props.canAccessStep) {
    return props.canAccessStep(step.id);
  }
  
  return false;
};

const getStepCursor = (step: Step) => {
  return isStepClickable(step) ? 'cursor-pointer' : 'cursor-not-allowed';
};

const handleStepClick = (step: Step) => {
  if (isStepClickable(step)) {
    emit('go-to-step', step.id);
  }
};

</script>

<template>
  <div class="p-4">
    <h2 class="text-lg font-semibold text-gray-900 mb-6">Checkout Process</h2>
    
    <div class="flow-root">
      <ul class="-mb-8">
        <li 
          v-for="(step, stepIdx) in steps" 
          :key="step.id" 
          class="relative pb-8"
        >
          <div 
            v-if="stepIdx !== steps.length - 1"
            class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200"
            :class="{
              'bg-blue-500': step.status === 'complete' || steps[stepIdx + 1].status === 'current'
            }"
          />
          
          <div class="relative flex items-start group">
            <div class="flex h-9 items-center">
              <span 
                v-if="step.status === 'complete'"
                class="relative z-10 flex h-8 w-8 items-center justify-center rounded-full bg-blue-500"
              >
                <svg class="h-5 w-5 " viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clip-rule="evenodd" />
                </svg>
              </span>
              <span 
                v-else-if="step.status === 'current'"
                
              >
                <span class="h-2.5 w-2.5 rounded-full bg-blue-500" />
              </span>
              <span 
                v-else
                class="relative z-10 flex h-8 w-8 items-center justify-center rounded-full border-2  bg-white"
              >
                <span class="h-2.5 w-2.5 rounded-full bg-transparent" />
              </span>
            </div>
            
            <div class="ml-4 flex min-w-0 flex-col">
              <button 
                type="button" 
                @click="handleStepClick(step)"
                :disabled="!isStepClickable(step)"
                :class="[
                  'text-left transition-all',
                  getStepCursor(step),
                  {
                    'text-blue-600 font-semibold': step.status === 'current',
                    'text-gray-900 hover:text-blue-600': step.status === 'complete' && isStepClickable(step),
                    'text-gray-400': step.status === 'upcoming' && !isStepClickable(step),
                    'opacity-50': !isStepClickable(step)
                  }
                ]"
              >
                {{ step.name }}
                <span v-if="!isStepClickable(step) && step.status === 'upcoming'" class="ml-2 text-xs">
                  🔒
                </span>
              </button>
              <p 
                v-if="step.status === 'complete'" 
                class="text-xs text-gray-500"
              >
                Completed
              </p>
              <p 
                v-else-if="step.status === 'current'" 
                class="text-xs text-blue-500"
              >
                In progress
              </p>
            </div>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>

<style scoped>
button {
  background: transparent !important;

  color: rgb(0, 0, 0) !important;

  font-weight: 600 !important;
  border: none !important;
  border-radius: 8px !important;
  padding: 0.5rem 1.25rem !important;
  box-shadow: 0 2px 8px rgba(37, 99, 235, 0.15) !important;
  transition: background 0.2s, transform 0.2s !important;
  cursor: pointer !important;
  outline: none !important;
}

button:hover, button:focus {
 background: linear-gradient(90deg, #4305b4 0%, #4305b4 1000%) !important;
  transform: translateY(-2px) scale(1.03) !important;
  color: white !important;
}

button:active {
  background: #4305b4 !important;
  color: white !important;
  border-radius: 50%;
  transform: scale(0.98) !important;
}

ul,ol {
  color : #ffffff !important; /* Tailwind's text-gray-900 */
}
</style>
