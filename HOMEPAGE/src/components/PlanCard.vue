<template>
  <div
    :class="[
      'relative rounded-xl p-6 cursor-pointer transition-all duration-200',
      'flex flex-col h-full',
      // Base styles for the card
      isFeatured 
        ? 'border-2 border-blue-500 bg-white shadow-stripe-lg hover:shadow-xl'
        : 'border border-gray-200 bg-white hover:border-gray-300 shadow-stripe-sm hover:shadow-md',
      // Selected state styles
      isSelected 
        ? 'ring-4 ring-blue-100 border-blue-600/70' 
        : ''
    ]"
    @click="$emit('select', planSlug)"
  >
    <div 
      class="absolute top-4 right-4 px-3 py-1 text-xs font-bold rounded-full uppercase tracking-wider"
      :class="badgeColor"
    >
      {{ badgeText }}
    </div>

    <h3 class="text-xl font-bold text-gray-900 mb-2 pr-16">{{ title }}</h3>
    
    <div class="mb-4">
      <span class="text-4xl font-extrabold text-gray-900 tracking-tight">{{ priceDisplay }}</span>
      <span v-if="priceSuffix" class="text-gray-500 text-sm ml-1">{{ priceSuffix }}</span>
    </div>
    
    <p class="text-sm text-gray-600 mb-6">{{ description }}</p>
    
    <div class="flex-grow">
      <ul class="space-y-3 mb-6">
        <li v-for="(feature, index) in features" :key="index" class="flex items-start text-sm text-gray-700">
          <svg class="w-5 h-5 text-blue-500 mr-2 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
          </svg>
          <span>{{ feature }}</span>
        </li>
      </ul>
    </div>

    <button
      type="button"
      class="w-full py-3 rounded-xl text-base font-semibold transition-all duration-150 mt-auto"
      :class="[
        isSelected 
          ? 'bg-blue-600 text-white shadow-md shadow-blue-500/20' 
          : isFeatured 
            ? 'bg-blue-600 text-white hover:bg-blue-700 shadow-md' 
            : 'bg-gray-100 text-gray-700 hover:bg-gray-200',
        // Specific style when selected on a non-featured card (to use primary color)
        isSelected && !isFeatured ? 'bg-blue-600 text-white hover:bg-blue-700' : ''
      ]"
      @click.stop="$emit('select', planSlug)"
    >
      {{ isSelected ? '✓ Currently Selected' : 'Select Plan' }}
    </button>
  </div>
</template>

<script setup lang="ts">


defineProps<{
  planSlug: string
  title: string
  priceDisplay: string
  priceSuffix?: string
  description: string
  badgeText: string
  badgeColor: string
  features: string[]
  isSelected: boolean
  isFeatured: boolean
}>()

defineEmits<{
  (e: 'select', planSlug: string): void
}>()
</script>