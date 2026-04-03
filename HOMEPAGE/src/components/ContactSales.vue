<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { post, get } from '@/services/api'
import Button from '@/components/ui/material.vue'
import { useBranding } from '@/services/branding'

const { businessName: brandingName } = useBranding()

// Props to control modal visibility
const props = defineProps<{
  isOpen: boolean
}>()

// Emits for parent component
const emit = defineEmits<{
  close: []
  submitted: [ticketId: number]
}>()

// Form data
interface ContactForm {
  name: string
  email: string
  company: string
  phone: string
  subject: string
  message: string
  queueId: number | null
}

interface Queue {
  id: number
  title: string
  description?: string
}

const form = ref<ContactForm>({
  name: '',
  email: '',
  company: '',
  phone: '',
  subject: 'Sales Inquiry',
  message: '',
  queueId: null
})

// Component state
const isSubmitting = ref(false)
const isSuccess = ref(false)
const errorMessage = ref('')
const queues = ref<Queue[]>([])
const ticketId = ref<number | null>(null)

// Form validation
const isValid = computed(() => {
  return form.value.name.trim() !== '' &&
         form.value.email.trim() !== '' &&
         form.value.subject.trim() !== '' &&
         form.value.message.trim() !== '' &&
         form.value.queueId !== null &&
         /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.value.email)
})

// Fetch available queues using the same approach as SupportTickets.vue
const fetchQueues = async () => {
  try {
    // This endpoint should fetch all available queues for the contact sales form
    const response = await get('helpdesk/api/queues/', { requireAuth: false })
    
    queues.value = Array.isArray(response) ? response : []
    
    // Filter for sales-related queues or use all public queues
    const filteredQueues = queues.value.filter((queue: Queue) => 
      queue.title.toLowerCase().includes('sales') || 
      queue.title.toLowerCase().includes('general') ||
      queue.title.toLowerCase().includes('support')
    )
    
    // Use filtered queues if available, otherwise use all queues
    const availableQueues = filteredQueues.length > 0 ? filteredQueues : queues.value
    queues.value = availableQueues
    
    // Set default queue (prefer 'sales' queue)
    const salesQueue = queues.value.find(q => q.title.toLowerCase().includes('sales'))
    const generalQueue = queues.value.find(q => q.title.toLowerCase().includes('general'))
    
    if (salesQueue) {
      form.value.queueId = salesQueue.id
    } else if (generalQueue) {
      form.value.queueId = generalQueue.id
    } else if (queues.value.length > 0) {
      form.value.queueId = queues.value[0].id
    }
  } catch (error) {
    console.error('Failed to fetch queues:', error)
    errorMessage.value = 'Failed to load form. Please try again later.'
    queues.value = []
  }
}

// Submit form
async function submitForm(): Promise<void> {
  if (!isValid.value || isSubmitting.value) return;

  isSubmitting.value = true;
  errorMessage.value = '';

  try {
    const requestData = {
      title: form.value.subject,
      description: `Name: ${form.value.name}\nEmail: ${form.value.email}\nCompany: ${form.value.company || 'Not provided'}\nPhone: ${form.value.phone || 'Not provided'}\n\nMessage:\n${form.value.message}`,
      submitter_email: form.value.email,
      queue: form.value.queueId,
      priority: 3 // Medium priority for sales inquiries
    };

    const response = await post('helpdesk/api/public/tickets/', requestData, { requireAuth: false }) as { id: number; };

    ticketId.value = response.id;
    isSuccess.value = true;

    setTimeout(() => {
      emit('submitted', response.id);
      closeModal();
    }, 3000);

  } catch (error) {
    console.error('Failed to submit contact form:', error);
    errorMessage.value = 'Failed to submit your inquiry. Please try again or contact us directly.';
  } finally {
    isSubmitting.value = false;
  }
}

// Reset form
const resetForm = () => {
  form.value = {
    name: '',
    email: '',
    company: '',
    phone: '',
    subject: 'Sales Inquiry',
    message: '',
    queueId: form.value.queueId // Keep the queue selection
  }
  isSuccess.value = false
  errorMessage.value = ''
}

// Close modal
const closeModal = () => {
  if (!isSubmitting.value) {
    // close view locally so dialog hides immediately
    visible.value = false
    resetForm()
    emit('close')
  }
}

// Local visible state synced with parent prop (used by PrimeVue Dialog)
const visible = ref(props.isOpen)

// Sync prop -> visible
watch(() => props.isOpen, (val) => visible.value = val)

// Sync visible -> parent & internal close
watch(visible, (val, old) => {
  if (old === true && val === false) {
    // Only close if not submitting (mirrors previous behavior)
    if (!isSubmitting.value) {
      closeModal()
    } else {
      // Prevent closing while submitting
      visible.value = true
    }
  }
})

// Subject options
const subjectOptions = [
  'Sales Inquiry',
  'Account Request',
  'Pricing Information',
  'Custom Solution',
  'Partnership Opportunity',
  'Enterprise Sales',
  'Reseller Program',
  'Technical Questions',
  'Other'
]

// Lifecycle
onMounted(() => {
  fetchQueues()
})
</script>

<template>
  <!-- PrimeVue Dialog -->
  <Dialog v-model:visible="visible" modal :blockScroll="true" :closable="!isSubmitting" :dismissableMask="!isSubmitting" :style="{ width: '740px', maxWidth: '90vw' }">
    <!-- Success State -->
    <div v-if="isSuccess" class="p-8 text-center">
                <!-- Success Icon -->
                <div class="w-20 h-20 mx-auto mb-6 bg-green-100 rounded-full flex items-center justify-center">

                </div>
                
                <!-- Success Message -->
                <h3 class="text-2xl font-bold text-neutral-900 mb-4">Thank You!</h3>
                <p class="text-neutral-600 mb-2">
                  Your sales inquiry has been submitted successfully.
                </p>
                <p class="text-sm text-black">
                  Ticket ID: #{{ ticketId }} - Our sales team will contact you within 24 hours.
                </p>
                
                <!-- Success Actions -->
                <div class="flex flex-col sm:flex-row gap-4 justify-center text-black">
                  <Button
                    component="Button"
                    id="success-close-btn"
                    label="Close"
                    @click="closeModal"
                    type="button"
                    variant="outlined"
                  >
                    Close
                  </Button>

                </div>
              </div>

              <!-- Form State -->
              <div v-else class="flex flex-col max-h-[120vh] mt-3">

                    <Button
                    component="Button"
                    id="submit-btn"
                    label="Send Message"
                    @click="submitForm"
                    :disabled="!isValid || isSubmitting"
                    type="submit"
                    variant="filled"
                    class="submitbtn"
                  >
                  </Button>

                <!-- Header -->
                <div class="mt-3 flex items-center justify-between p-2 border-b border-neutral-200">
              
                  <div>
                    <h2 class="text-2xl  font-bold text-neutral-900">Submit Account Request</h2>
                    <p class="text-neutral-600 mt-1">Let's discuss how {{ brandingName }} can help your business grow</p>
                  </div>
          
                </div>

                <!-- Form Content -->
                <div class="contact-sales-body flex-1 overflow-y-auto p-6">
                  <form @submit.prevent="submitForm" class="space-y-4">
                    <!-- Error Message -->
                    <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 rounded-xl">
                      <div class="flex items-center">

                        <p class="text-red-800 font-medium">{{ errorMessage }}</p>
                      </div>
                    </div>

                    <!-- Form Grid - Two Column Layout -->
                    <div class="grid grid-cols-2 gap-4">
                      <!-- Name -->
                      <div class="space-y-1.5">
                        <label for="name" class="block text-sm font-semibold text-neutral-700">
                          Full Name *
                        </label>
                        <input
                          id="name"
                          v-model="form.name"
                          type="text"
                          required
                          :disabled="isSubmitting"
                          class="w-full px-4 py-2.5 border border-neutral-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors disabled:bg-neutral-50 disabled:cursor-not-allowed"
                          placeholder="John Doe"
                        />
                      </div>

                      <!-- Email -->
                      <div class="space-y-1.5">
                        <label for="email" class="block text-sm font-semibold text-neutral-700">
                          Email Address *
                        </label>
                        <input
                          id="email"
                          v-model="form.email"
                          type="email"
                          required
                          :disabled="isSubmitting"
                          class="w-full px-4 py-2.5 border border-neutral-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors disabled:bg-neutral-50 disabled:cursor-not-allowed"
                          placeholder="john@company.com"
                        />
                      </div>

                      <!-- Company -->
                      <div class="space-y-1.5">
                        <label for="company" class="block text-sm font-semibold text-neutral-700">
                          Company
                        </label>
                        <input
                          id="company"
                          v-model="form.company"
                          type="text"
                          :disabled="isSubmitting"
                          class="w-full px-4 py-2.5 border border-neutral-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors disabled:bg-neutral-50 disabled:cursor-not-allowed"
                          placeholder="Your Company Name"
                        />
                      </div>

                      <!-- Phone -->
                      <div class="space-y-1.5">
                        <label for="phone" class="block text-sm font-semibold text-neutral-700">
                          Phone Number
                        </label>
                        <input
                          id="phone"
                          v-model="form.phone"
                          type="tel"
                          :disabled="isSubmitting"
                          class="w-full px-4 py-2.5 border border-neutral-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors disabled:bg-neutral-50 disabled:cursor-not-allowed"
                          placeholder="+1 (555) 123-4567"
                        />
                      </div>

                      <!-- Subject -->
                      <div class="space-y-1.5">
                        <label for="subject" class="block text-sm font-semibold text-neutral-700">
                          Subject *
                        </label>
                        <select
                          id="subject"
                          v-model="form.subject"
                          required
                          :disabled="isSubmitting"
                          class="w-full px-4 py-2.5 border border-neutral-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors disabled:bg-neutral-50 disabled:cursor-not-allowed"
                        >
                          <option v-for="option in subjectOptions" :key="option" :value="option">
                            {{ option }}
                          </option>
                        </select>
                      </div>

                      <!-- Department/Queue Selection -->
                      <div class="space-y-1.5">
                        <label for="queue" class="block text-sm font-semibold text-neutral-700">
                          Department *
                        </label>
                        <select
                          id="queue"
                          v-model="form.queueId"
                          required
                          :disabled="isSubmitting"
                          class="w-full px-4 py-2.5 border border-neutral-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors disabled:bg-neutral-50 disabled:cursor-not-allowed"
                        >
                          <option :value="null" disabled>Select a department</option>
                          <option v-for="queue in queues" :key="queue.id" :value="queue.id">
                            {{ queue.title }}
                          </option>
                        </select>
                        <p v-if="queues.length === 0" class="text-xs text-neutral-500 mt-1">
                          Loading departments... If this persists, please try again later.
                        </p>
                      </div>
                    </div>
                    
                     <br>
                

                    <!-- Message - Full Width -->
                    <div class="main-text-area min-w-full space-y-1.5">
                      <label for="message" class="block text-sm font-semibold text-neutral-700">
                        Message *
                      </label>
                      <textarea
                        id="message"
                        v-model="form.message"
                        required
                        rows="5"
                        :disabled="isSubmitting"
                        class="min-w-full px-4 py-2.5 border border-neutral-300 rounded-xl focus:ring-2 focus:ring-orange-500 focus:border-orange-500 transition-colors resize-none disabled:bg-neutral-50 disabled:cursor-not-allowed"
                        placeholder="Tell us about your hosting needs, expected traffic, special requirements, or any questions you have..."
                      ></textarea>

                      
              
                    </div>
                  </form>
                                  <div class="contact-sales-actions flex flex-col sm:flex-row gap-4 p-6 border-t border-neutral-200 bg-neutral-50">
                  <Button
                    component="Button"
                    id="cancel-btn"
                    label="Cancel"
                    @click="closeModal"
                    :disabled="isSubmitting"
                    type="button"
                    variant="outlined"
                  >
                    Cancel
                  </Button>
                  <Button
                    component="Button"
                    id="submit-btn"
                    label="Send Message"
                    @click="submitForm"
                    :disabled="!isValid || isSubmitting"
                    type="submit"
                    variant="filled"
                    class="submitbtn"
                  >
                    <!-- Loading Spinner -->

                    {{ isSubmitting ? 'Submitting...' : 'Send Message' }}
                  </Button>
                </div>
                </div>

                <!-- Footer Actions -->


                <!-- Contact Info Footer -->
            
              </div>
  </Dialog>
</template>

<style scoped>

.contact-sales-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  overflow-y: auto;
}

.contact-sales-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(17, 17, 17, 0.75);
  backdrop-filter: blur(6px);
}

.contact-sales-container {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem;
}

.contact-sales-modal {
  position: relative;
  width: 100%;
  max-width: 640px;
  max-height: 100vh;
  background: #ffffff;
  border-radius: 20px;
 
  box-shadow: 0 25px 60px rgba(15, 23, 42, 0.35);
  display: flex;
  flex-direction: column;
  margin: auto;
}

.contact-sales-body {
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem;
}

.contact-sales-actions {
  border-top: 1px solid #e5e7eb;
  background: #ffffff;
  padding: 1.5rem;
  flex-shrink: 0;
}

.contact-sales-info {
  padding: 0 1rem 1rem 1rem;
  text-align: center;
  margin-top: -1% !important;
}

/* Custom scrollbar for the modal content */
.contact-sales-body::-webkit-scrollbar {
  width: 8px;
}

.contact-sales-body::-webkit-scrollbar-track {
  background: #202122;
  border-radius: 4px;
  color: white;
}

.contact-sales-body::-webkit-scrollbar-thumb {
  background: #202122;
  border-radius: 4px;
  color: white;
}

.contact-sales-body::-webkit-scrollbar-thumb:hover {
  background: #202122;
  border-radius: 4px;
  color: white;
}

/* Focus styles for better accessibility */
input:focus,
select:focus,
textarea:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(246, 135, 2, 0.2);
  border-color: #f68702;
}

/* Smooth transitions for form elements */
input,
select,
textarea {
  transition: all 0.2s ease-in-out;
}

/* Loading animation for submit Button */
@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.animate-spin {
  animation: spin 1s linear infinite;
}

.animate-on-scroll {

  transform: translateY(30px);
  transition: all 0.6s ease-out;
}

.animate-on-scroll.animate {

  transform: translateY(10);
}



.contact-sales-modal textarea {
  min-width: 100%;
  background-color: #ffffff;
  color: #374151;
  border: 1px solid #d1d5db;
  font-size: 0.875rem;
  line-height: 1.25rem;
  border-radius: 0.75rem;
  padding: 0.75rem 1rem;
  transition: border-color 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
}

.contact-sales-modal select {
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
  background-position: right 0.75rem center;
  background-repeat: no-repeat;
  background-size: 1.25em 1.25em;
  -webkit-appearance: none;
  appearance: none;
  float: right !important;
}

.contact-sales-modal label {
  color: #374151;
  font-weight: 600;
  font-size: 0.875rem;
 
  margin-left: 10px;
}

.contact-sales-modal h2,
.contact-sales-modal h3,
.contact-sales-modal h4 {
  color: #111827;
}

.contact-sales-modal p {
  color: #6b7280;
}

.contact-sales-modal div {

  margin-left: 10px;
  display: inline-block;
  grid-template-columns: min-content;

}

input,
select {
  /* `block w-full` */
  display: block;
  width: 100%;

  /* `px-3 py-3` (0.75rem = 12px) */
  padding: 0.75rem;

  /* `text-sm text-gray-900` */
  font-size: 0.875rem; /* 14px */
  line-height: 1.25rem; /* 20px */
  color: #000000; /* Equivalent to text-gray-900 */

  /* `bg-transparent` */
  background-color: transparent;

  /* `rounded-md border` */
  border: 1px solid #D1D5DB; /* Default border color, equivalent to gray-300 */
  border-radius: 0.375rem; /* 6px */

  /* `appearance-none` */
  -webkit-appearance: none;
  appearance: none;

  /* Smooth transition for focus states */
  transition: border-color 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
}

/*
 * Custom styles specifically for the select element to add a dropdown arrow,
 * since `appearance: none;` removes the default one.
 */
select {
  /* Custom SVG icon for the dropdown arrow */
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e");
  background-position: right 0.5rem center;
  background-repeat: no-repeat;
  background-size: 1.5em 1.5em;
  padding-right: 2.5rem; /* Add padding to make space for the arrow */
}

/*
 * Styles for form elements when they are in focus.
 * This combines `focus:outline-none`, `focus:ring-2`, and `focus:border-blue-500`.
 */
input:focus,
select:focus {
  /* `focus:outline-none` */
  outline: none;



  /* `focus:ring-2` */
  /* This creates the ring effect using box-shadow */
 
}

/*
 * Override text color for inputs/selects on dark backgrounds
 * Targets elements with dark slate backgrounds (bg-slate-900, bg-slate-950, etc.)
 */
input[class*="bg-slate-900"],
input[class*="bg-slate-950"],
select[class*="bg-slate-900"],
select[class*="bg-slate-950"],
.bg-slate-900 input,
.bg-slate-950 input,
.bg-slate-900 select,
.bg-slate-950 select {
  color: #ffffff !important;
}

/* Also target option elements in selects with dark backgrounds */
select[class*="bg-slate-900"] option,
select[class*="bg-slate-950"] option,
.bg-slate-900 select option,
.bg-slate-950 select option {
  background-color: #0f172a; /* slate-900 */
  color: #ffffff;
}


.main-text-area {
  max-height: 90px;
  overflow-y: auto;
  min-height: 150px;
  font-weight: normal;
  min-width: 100vw;
}

.submitbtn {
  margin-left: 12px !important;
  background-color: black !important;
  color : white !important;
}

textarea {
      font: inherit;
    font-feature-settings: inherit;
    font-variation-settings: inherit;
    letter-spacing: inherit;
    color: inherit;
    border-radius: 8px;
    background-color: transparent;
    opacity: 1;
    min-width: 30%;
    border: 2px solid;
    border-color: #ff9d00;
}

</style>
