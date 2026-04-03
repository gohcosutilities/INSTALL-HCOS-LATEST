<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="isOpen" class="modal-overlay" @click="handleOverlayClick">
        <div class="modal-container" @click.stop>
          <button class="close-button" @click="closeModal" aria-label="Close modal">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>

          <div class="modal-content">
            <div v-if="!isSuccess" class="form-view">
              <div class="icon-wrapper">
                <h1>{{ brandingNameWithIO }}</h1>
              </div>

              <h2 class="title">Give {{ brandingName }} A Test Drive</h2>
              <p class="subtitle">
                Experience the power of our Hosting And Commerce Operating System. Enter your email to receive instant access.
              </p>

              <form @submit.prevent="handleSubmit">
                <div class="form-group">
                  <label for="email" class="form-label">Email Address</label>
                  <input
                    id="email"
                    v-model="email"
                    type="email"
                    class="form-input"
                    :class="{ 'input-error': error }"
                    placeholder="you@example.com"
                    required
                    :disabled="isLoading"
                  />
                  <p v-if="error" class="error-message">{{ error }}</p>
                </div>

                <button
                  type="submit"
                  class="submit-button"
                  :disabled="isLoading || !email"
                  :class="{ 'button-loading': isLoading }"
                >
                  <i class="pi pi-send"></i>
                  <span v-if="!isLoading">Send</span>
                  <span v-else class="loading-content">
                    <svg class="spinner" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                      <path d="M21 12a9 9 0 1 1-6.219-8.56"></path>
                    </svg>
                    Sending...
                  </span>
                </button>
              </form>

              <p class="privacy-note">
                We respect your privacy. Your email will only be used to send you the access link.
              </p>
            </div>

            <div v-else class="success-view">
              <div class="success-icon-wrapper">
                <svg class="success-icon" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                  <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
              </div>

              <h2 class="success-title">Check Your Email!</h2>
              <p class="success-message">
                We've sent the access link to <strong>{{ email }}</strong>.
                Please check your inbox and spam folder.
              </p>

              <button @click="closeModal" class="done-button">
                Done
              </button>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, onBeforeMount, computed } from 'vue'
import { get, post } from "@/services/api"
import hcosLogo from '@/assets/logos/hcosLogo.png'
import { useBranding } from '@/services/branding'

const { businessName } = useBranding()
const brandingName = businessName
const brandingNameWithIO = computed(() => `${businessName.value}.io`)

const errorMessage = ref('')
const props = defineProps<{
  modelValue: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  'success': [email: string]
}>()

const queues = ref<Array<() => void>>([])
const form = ref<{
  queueId: number | null
}>({
  queueId: null
})


const isOpen = ref(props.modelValue)
const email = ref('')
const isLoading = ref(false)
const isSuccess = ref(false)
const error = ref('')

watch(() => props.modelValue, (newValue) => {
  isOpen.value = newValue
  if (newValue) {
    resetForm()
  }
})

const closeModal = () => {
  emit('update:modelValue', false)
}

const handleOverlayClick = () => {
  closeModal()
}

const resetForm = () => {
  email.value = ''
  error.value = ''
  isSuccess.value = false
  isLoading.value = false
}

const handleSubmit = async () => {
  error.value = ''

  if (!email.value || !isValidEmail(email.value)) {
    error.value = 'Please enter a valid email address'
    return
  }

  isLoading.value = true

  try {
    await submitDemoRequest(email.value)
    isSuccess.value = true
    emit('success', email.value)
  } catch (err: any) {
    error.value = err.message || 'Something went wrong. Please try again.'
  } finally {
    isLoading.value = false
  }
}

const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// Fetch the available queues 

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

const submitDemoRequest = async (emailAddress: string): Promise<void> => {
  const formData = new FormData()
  formData.append('submitter_email', emailAddress)
  formData.append('title', `${brandingName.value} Account Request`)
  formData.append('description', `Account access requested for ${brandingName.value} - Hosting And Commerce Operating System`)
  formData.append('send_email_notification', 'false')
  formData.append('is_demo_request', 'true')
  if (form.value.queueId) {
    formData.append('queue', form.value.queueId.toString())
  }
  await post('helpdesk/api/public/tickets/', formData)
}

onBeforeMount( () => {
  // remove kc-token from localStorage to prevent auth issues
  localStorage.removeItem('kc-token')
})

onMounted(async () => {
  await fetchQueues()
})

</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 16px;
}

.modal-container {
  background: linear-gradient(135deg, #061342 90%, #d7d5de 10%);
  border-radius: 20px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  max-width: 480px;
  width: 100%;
  position: relative;
  overflow: hidden;
}

.modal-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, #0066cc, #0099ff);
}

.close-button {
  position: absolute;
  top: 16px;
  right: 16px;
  background: transparent;
  border: none;
  color: #64748b;
  cursor: pointer;
  padding: 8px;
  border-radius: 8px;
  transition: all 0.2s ease;
  z-index: 10;
}

.close-button:hover {
  background: rgba(0, 0, 0, 0.05);
  color: #334155;
}

.modal-content {
  padding: 48px 40px;
}

.form-view,
.success-view {
  text-align: center;
}

.icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 80px;
  height: 80px;
  margin: 0 auto 24px;
  background: linear-gradient(135deg, #f7f8fa 0%, #15181b 100%);
  border-radius: 20px;
  box-shadow: 0 8px 24px rgba(0, 102, 204, 0.3);
}

.icon {
  color: white;
}

.title {
  font-size: 28px;
  font-weight: 700;
  color: #e9e9ea;
  margin: 0 0 12px;
  line-height: 1.2;
}

.subtitle {
  font-size: 16px;
  color: #eff1f4;
  margin: 0 0 32px;
  line-height: 1.5;
}

.form-group {
  margin-bottom: 24px;
  text-align: left;
}

.form-label {
  display: block;
  font-size: 14px;
  font-weight: 600;
  color: #e8e8e8;
  margin-bottom: 8px;
}

.form-input {
  width: 100%;
  padding: 14px 16px;
  font-size: 16px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  transition: all 0.2s ease;
  background: white;
  color: #1e293b;
  font-family: inherit;
}

.form-input:focus {
  outline: none;
  border-color: #0066cc;
  box-shadow: 0 0 0 4px rgba(0, 102, 204, 0.1);
}

.form-input:disabled {
  background: #f1f5f9;
  cursor: not-allowed;
}

.form-input.input-error {
  border-color: #ef4444;
}

.form-input.input-error:focus {
  box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.1);
}

.error-message {
  margin: 8px 0 0;
  font-size: 14px;
  color: #ef4444;
  text-align: left;
}

.submit-button {
  width: 100%;
  padding: 14px 24px;
  font-size: 16px;
  font-weight: bold;
  color: white;
  background: linear-gradient(135deg, #01020236 90%, #3c3179 10%);
  border: 2px solid #edeff2;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(0, 102, 204, 0.3);
}

.submit-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 102, 204, 0.4);
}

.submit-button:active:not(:disabled) {
  transform: translateY(0);
}

.submit-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.submit-button.button-loading {
  opacity: 0.8;
}

.loading-content {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.spinner {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.privacy-note {
  margin: 24px 0 0;
  font-size: 13px;
  color: #94a3b8;
  line-height: 1.5;
}

.success-icon-wrapper {
  margin: 0 auto 24px;
}

.success-icon {
  color: #10b981;
  animation: successPop 0.5s ease-out;
}

@keyframes successPop {
  0% {
    transform: scale(0);
    opacity: 0;
  }
  50% {
    transform: scale(1.1);
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

.success-title {
  font-size: 28px;
  font-weight: 700;
  color: #ededed;
  margin: 0 0 16px;
}

.success-message {
  font-size: 16px;
  color: #64748b;
  margin: 0 0 32px;
  line-height: 1.6;
}

.success-message strong {
  color: #0066cc;
  font-weight: 600;
}

.done-button {
  padding: 14px 32px;
  font-size: 16px;
  font-weight: 600;
  color: #0066cc;
  background: rgba(0, 102, 204, 0.1);
  border: 2px solid #0066cc;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.done-button:hover {
  background: #0066cc;
  color: white;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-container,
.modal-leave-active .modal-container {
  transition: transform 0.3s ease;
}

.modal-enter-from .modal-container,
.modal-leave-to .modal-container {
  transform: scale(0.9);
}

@media (prefers-color-scheme: dark) {
  .modal-container {
    background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  }

  .close-button {
    color: #94a3b8;
  }

  .close-button:hover {
    background: rgba(255, 255, 255, 0.1);
    color: #e2e8f0;
  }

  .title,
  .success-title {
    color: #f1f5f9;
  }

  .subtitle,
  .success-message {
    color: #94a3b8;
  }

  .form-label {
    color: #cbd5e1;
  }

  .form-input {
    background: #0f172a;
    border-color: #334155;
    color: #f1f5f9;
  }

  .form-input:disabled {
    background: #1e293b;
  }

  .privacy-note {
    color: #64748b;
  }
}

@media (max-width: 640px) {
  .modal-content {
    padding: 40px 24px;
  }

  .title,
  .success-title {
    font-size: 24px;
  }

  .subtitle,
  .success-message {
    font-size: 14px;
  }
}
</style>
