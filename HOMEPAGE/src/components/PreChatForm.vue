<template>
  <div class="fixed bottom-5 right-5 z-50">
    <!-- Chat Bubble (when form is hidden) -->
    <button 
      v-if="!showForm" 
      @click="showForm = true"
      class="bg-[#0a2a4b] text-white rounded-full p-4 shadow-lg hover:bg-white hover:text-black focus:outline-none focus:ring-2 focus:ring-[#0a2a4b] focus:ring-opacity-50 transition-transform transform hover:scale-110"
    >
      <MessageSquare :size="32" />
    </button>

    <!-- Pre-Chat Form -->
    <div 
      v-if="showForm"
      class="w-[90vw] md:w-[400px] bg-white rounded-2xl shadow-2xl flex flex-col transition-all duration-300 ease-in-out"
    >
      <!-- Header -->
      <header class="bg-[#09263a] text-white p-4 flex justify-between items-center rounded-t-2xl shadow-md">
        <h2 class="text-lg font-semibold">Start a Conversation</h2>
        <button @click="closeForm" class="text-black hover:text-blue-200">
          <X :size="24" />
        </button>
      </header>

      <!-- Form Content -->
      <div class="p-6">
        <p class="text-gray-600 text-sm mb-4">
          Please provide your details to start chatting with our support team.
        </p>

        <form @submit.prevent="handleSubmit">
          <div class="mb-4">
            <label for="guest_name" class="block text-sm font-medium text-gray-700 mb-2">
              Your Name <span class="text-red-500">*</span>
            </label>
            <input
              id="guest_name"
              v-model="formData.guest_name"
              type="text"
              required
              placeholder="Enter your name"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div class="mb-6">
            <label for="guest_email" class="block text-sm font-medium text-gray-700 mb-2">
              Your Email <span class="text-gray-400 text-xs">(Optional)</span>
            </label>
            <input
              id="guest_email"
              v-model="formData.guest_email"
              type="email"
              placeholder="your.email@example.com"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <p class="mt-1 text-xs text-gray-500">
              We'll use this to follow up if needed
            </p>
          </div>

          <div class="flex gap-3">
            <button
              type="button"
              @click="closeForm"
              class="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="!formData.guest_name.trim() || isSubmitting"
              class="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center"
            >
              <Loader v-if="isSubmitting" :size="18" class="animate-spin mr-2" />
              {{ isSubmitting ? 'Starting...' : 'Start Chat' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { MessageSquare, X, Loader } from 'lucide-vue-next';

const emit = defineEmits(['start-chat']);

const showForm = ref(false);
const isSubmitting = ref(false);
const formData = ref({
  guest_name: '',
  guest_email: ''
});

const handleSubmit = async () => {
  if (!formData.value.guest_name.trim()) return;
  
  isSubmitting.value = true;
  
  try {
    // Emit the form data to parent component
    emit('start-chat', {
      guest_name: formData.value.guest_name.trim(),
      guest_email: formData.value.guest_email.trim() || null
    });
  } catch (error) {
    console.error('Error starting chat:', error);
    alert('Failed to start chat. Please try again.');
    isSubmitting.value = false;
  }
};

const closeForm = () => {
  showForm.value = false;
  formData.value = {
    guest_name: '',
    guest_email: ''
  };
};
</script>
