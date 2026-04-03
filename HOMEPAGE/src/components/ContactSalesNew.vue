<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div v-if="visible" class="fixed inset-0 z-[9999] flex items-center justify-center p-4 sm:p-6"
        @click.self="closeModal">

        <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity"></div>

        <div
          class="relative bg-white rounded-2xl shadow-2xl w-full max-w-5xl flex flex-col max-h-[95vh] transition-all transform">

          <div
            class="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-[#2a294f]/5 to-transparent rounded-t-2xl pointer-events-none">
          </div>

          <button v-if="!isSubmitting" @click="closeModal" class="absolute top-4 right-4 z-20 w-8 h-8 flex items-center justify-center
         rounded-full bg-white hover:bg-slate-100
         text-[#2a294f] hover:text-black
         transition-all shadow-sm border border-slate-100" aria-label="Close">
        X
          </button>

          <div v-if="isSuccess"
            class="relative z-10 flex flex-col items-center justify-center h-full min-h-[400px] p-8 text-center">
            <div class="w-20 h-20 mb-6 bg-green-50 rounded-full flex items-center justify-center shadow-sm">
              <svg class="w-10 h-10 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
              </svg>
            </div>
            <h3 class="text-2xl font-bold text-slate-900 mb-2">Request Submitted</h3>
            <p class="text-slate-600 mb-6">We're setting up your environment.</p>
            <div
              class="inline-flex items-center px-3 py-1 rounded-full bg-slate-100 text-slate-500 text-sm font-medium animate-pulse">
              Redirecting...
            </div>
          </div>

          <div v-else class="flex flex-col h-full min-h-0">
            <div class="flex-1 min-h-0 overflow-y-auto custom-scrollbar">
              <div class="px-8 pt-8 pb-4 text-center z-10">
                <h2 class="text-2xl md:text-3xl font-bold text-slate-900 tracking-tight">Select your plan</h2>
                <p class="text-slate-500 mt-1">Choose Any Plan And Change it later if needed.</p>
              </div>

              <div v-if="errorMessage" class="px-8 pb-2">
                <div class="p-3 bg-red-50 border-l-4 border-red-500 rounded-r-md flex items-center gap-3">
                  <span class="text-red-700 text-sm font-medium">{{ errorMessage }}</span>
                </div>
              </div>

              <div class="px-6 sm:px-8 py-2">
                <div v-if="plansLoading" class="py-6 text-center text-sm text-slate-500">
                  Loading plans...
                </div>
                <div v-else class="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div
                    v-for="plan in plans"
                    :key="plan.slug"
                    class="relative border-2 rounded-xl p-5 cursor-pointer transition-all duration-200 flex flex-col h-full"
                    :class="selectedPlan === plan.slug
                      ? 'border-[#2a294f] bg-[#2a294f]/5 shadow-sm'
                      : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'"
                    @click="selectPlan(plan.slug)"
                  >
                    <div v-if="plan.badge"
                      class="absolute top-0 right-0 bg-[#2a294f] text-white text-[10px] font-bold px-3 py-1 rounded-bl-xl rounded-tr-lg uppercase tracking-wider">
                      {{ plan.badge }}
                    </div>

                    <div class="flex justify-between items-start mb-2">
                      <h3 class="font-bold text-slate-900">{{ plan.title }}</h3>
                      <div class="w-5 h-5 rounded-full border flex items-center justify-center"
                        :class="selectedPlan === plan.slug ? 'border-[#2a294f] bg-[#2a294f]' : 'border-slate-300'">
                        <div v-if="selectedPlan === plan.slug" class="w-2 h-2 bg-white rounded-full"></div>
                      </div>
                    </div>

                    <div class="mb-3 flex items-baseline">
                      <span class="text-3xl font-bold text-slate-900">{{ plan.priceMain }}</span>
                      <span v-if="plan.priceSub" class="text-slate-500 ml-1 text-sm">{{ plan.priceSub }}</span>
                    </div>

                    <ul class="space-y-2 mb-3 flex-grow">
                      <li
                        v-for="(feature, idx) in plan.previewFeatures"
                        :key="idx"
                        class="flex items-center text-xs text-slate-600"
                      >
                        <svg class="w-4 h-4 text-[#2a294f] mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                        {{ feature }}
                      </li>
                    </ul>

                    <button
                      type="button"
                      class="mt-auto w-full text-xs font-semibold text-[#2a294f] hover:underline disabled:opacity-60 disabled:cursor-not-allowed"
                      :disabled="isSubmitting"
                      @click.stop="openFeatures(plan)"
                    >
                      More Info
                    </button>
                  </div>
                </div>
              </div>

              <div class="px-8 py-6 bg-slate-50 border-t border-slate-100 rounded-b-2xl mt-4">
                <div class="flex flex-col md:flex-row gap-4 items-end">
                  <div class="w-full md:flex-grow">
                    <label for="email"
                      class="block text-xs font-semibold text-slate-700 mb-1 ml-1 uppercase tracking-wide">
                      Work Email Address
                    </label>
                    <input id="email" v-model="form.email" type="email" required :disabled="isSubmitting"
                      class="w-full px-4 py-3 bg-white border rounded-lg text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 transition-all disabled:bg-slate-100"
                      :class="emailError
                        ? 'border-red-400 focus:border-red-500 focus:ring-red-200'
                        : 'border-slate-300 focus:border-[#2a294f] focus:ring-[#2a294f]/20'"
                      placeholder="name@company.com"
                      @input="onEmailInput"
                      @blur="onEmailBlur" />
                    <div v-if="emailChecking" class="mt-1 flex items-center text-xs text-slate-400">
                      <svg class="animate-spin h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"></path>
                      </svg>
                      Checking availability...
                    </div>
                    <p v-else-if="emailError" class="mt-1 text-xs text-red-600 font-medium">{{ emailError }}</p>
                  </div>

                  <button @click="submitForm" :disabled="!isValid || isSubmitting" type="button"
                    class="w-full md:w-auto px-8 py-3 bg-[#2a294f] text-white rounded-lg font-semibold hover:bg-[#5851df] shadow-md shadow-indigo-200 disabled:opacity-50 disabled:shadow-none disabled:cursor-not-allowed transition-all flex items-center justify-center whitespace-nowrap">
                    <svg v-if="isSubmitting" class="animate-spin h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor"
                        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
                      </path>
                    </svg>
                    <span>{{ isSubmitting ? 'Processing...' : 'Create Account' }}</span>
                  </button>
                </div>
                <p class="text-center md:text-left text-[10px] text-slate-400 mt-3">
                  By clicking "Create Account", you agree to our <a href="#"
                    class="text-[#2a294f] hover:underline">Terms</a> & <a href="#"
                    class="text-[#2a294f] hover:underline">Privacy</a>.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>

  <Teleport to="body">
    <Transition name="modal-fade">
      <div v-if="featuresVisible" class="fixed inset-0 z-[10000] flex items-center justify-center p-4 sm:p-6"
        @click.self="closeFeatures">
        <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm transition-opacity"></div>
        <div class="relative bg-white rounded-2xl shadow-2xl w-full max-w-2xl flex flex-col max-h-[95vh]">
          <button v-if="!isSubmitting" @click="closeFeatures" class="absolute top-4 right-4 z-20 w-8 h-8 flex items-center justify-center
         rounded-full bg-white hover:bg-slate-100
         text-[#2a294f] hover:text-black
         transition-all shadow-sm border border-slate-100" aria-label="Close">
            X
          </button>

          <div class="px-8 pt-8 pb-4">
            <h3 class="text-xl font-bold text-slate-900">{{ activePlan?.title }}</h3>
            <p class="text-slate-500 mt-1">Plan details and included features</p>
          </div>

          <div class="px-8 pb-8 overflow-y-auto custom-scrollbar">
            <div class="border border-slate-200 rounded-xl p-5 bg-white">
              <div class="flex items-baseline mb-4">
                <span class="text-2xl font-bold text-slate-900">{{ activePlan?.priceMain }}</span>
                <span v-if="activePlan?.priceSub" class="text-slate-500 ml-2 text-sm">{{ activePlan?.priceSub }}</span>
              </div>

              <ul class="space-y-3">
                <li v-for="(feature, idx) in (activePlan?.features || [])" :key="idx" class="flex items-start text-sm text-slate-700">
                  <svg class="w-5 h-5 text-[#2a294f] mr-3 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                  </svg>
                  <span>{{ feature }}</span>
                </li>
              </ul>

              <div v-if="!activePlan?.features?.length" class="text-sm text-slate-500">
                No features available.
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { post, get } from '@/services/api'

const props = defineProps<{
  isOpen: boolean
}>()

const emit = defineEmits<{
  close: []
  submitted: [ticketId: number]
}>()

type SalesPlan = {
  slug: string
  title: string
  badge?: string
  priceMain: string
  priceSub?: string
  previewFeatures: string[]
  features: string[]
}

const defaultPlans: SalesPlan[] = [
  {
    slug: 'hcos-base-plan',
    title: 'Base',
    priceMain: '$0',
    priceSub: '/mo',
    previewFeatures: ['2 Users', '2 Staff', 'Basic Support'],
    features: ['2 Users', '2 Staff', 'Basic Support']
  },
  {
    slug: 'hcos-small-business-plan',
    title: 'Small Business',
    badge: 'Popular',
    priceMain: '$10',
    priceSub: '/mo',
    previewFeatures: ['200 Users', '10 Staff', 'Priority Support', 'Advanced Features'],
    features: ['200 Users', '10 Staff', 'Priority Support', 'Advanced Features']
  },
  {
    slug: 'hcos-enterprise-plan',
    title: 'Enterprise',
    priceMain: 'Custom',
    previewFeatures: ['Unlimited Users', 'Unlimited Staff', '24/7 Support', 'Account Manager'],
    features: ['Unlimited Users', 'Unlimited Staff', '24/7 Support', 'Account Manager']
  }
]

const selectedPlan = ref<string>('hcos-small-business-plan')
const plans = ref<SalesPlan[]>(defaultPlans)
const plansLoading = ref(false)
const form = ref({ email: '' })
const isSubmitting = ref(false)
const isSuccess = ref(false)
const errorMessage = ref('')
const ticketId = ref<number | null>(null)
const visible = ref(props.isOpen)

// ── Email pre-validation state ──
const emailError = ref('')
const emailChecking = ref(false)
let emailCheckTimer: ReturnType<typeof setTimeout> | null = null

// ── Dynamic queue state ──
const salesQueueId = ref<number | null>(null)

const featuresVisible = ref(false)
const activePlan = ref<SalesPlan | null>(null)

const isValid = computed(() => {
  return selectedPlan.value &&
    form.value.email.trim() !== '' &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.value.email) &&
    !emailError.value &&
    !emailChecking.value
})

const selectPlan = (planSlug: string) => {
  selectedPlan.value = planSlug
}

const openFeatures = (plan: SalesPlan) => {
  activePlan.value = plan
  featuresVisible.value = true
}

const closeFeatures = () => {
  featuresVisible.value = false
  activePlan.value = null
}

const getPlanName = (slug: string): string => {
  const names: Record<string, string> = {
    'hcos-base-plan': 'HCOS Base (Free)',
    'hcos-small-business-plan': 'HCOS Small Business ($10/month)',
    'hcos-enterprise-plan': 'HCOS Enterprise (Custom Pricing)'
  }
  return names[slug] || slug
}

// ── Email duplicate check (debounced) ──
const checkEmailExists = async (email: string) => {
  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    emailError.value = ''
    return
  }

  emailChecking.value = true
  emailError.value = ''

  try {
    const result = await post<{ email: string }, {
      valid: boolean
      exists: boolean
      message: string
      error?: string
    }>('helpdesk/api/public/account-request/check-email/', { email }, { requireAuth: false })

    if (result.exists) {
      emailError.value = result.message || 'This email is already registered. Please sign in instead.'
    } else {
      emailError.value = ''
    }
  } catch (err: any) {
    // Non-critical: if the check fails, let the user proceed;
    // the backend create() will catch it.
    console.warn('Email check failed:', err)
    emailError.value = ''
  } finally {
    emailChecking.value = false
  }
}

const onEmailInput = () => {
  // Clear previous error immediately on new input
  emailError.value = ''
  errorMessage.value = ''

  if (emailCheckTimer) clearTimeout(emailCheckTimer)
  const email = form.value.email.trim()

  if (email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    emailCheckTimer = setTimeout(() => checkEmailExists(email), 600)
  }
}

const onEmailBlur = () => {
  const email = form.value.email.trim()
  if (email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    if (emailCheckTimer) clearTimeout(emailCheckTimer)
    checkEmailExists(email)
  }
}

// ── Fetch the sales queue ID from the backend ──
const fetchSalesQueue = async (): Promise<void> => {
  try {
    const result = await get<{ queue_id: number; queue_title: string }>(
      'helpdesk/api/public/account-request/sales-queue/',
      { requireAuth: false }
    )
    salesQueueId.value = result.queue_id
  } catch (err) {
    console.warn('Could not fetch sales queue, submission will let the backend resolve it:', err)
    salesQueueId.value = null
  }
}

// ── Submit form ──
async function submitForm(): Promise<void> {
  if (!isValid.value || isSubmitting.value) return

  isSubmitting.value = true
  errorMessage.value = ''

  try {
    // Build request — use dynamic queue or omit to let the backend pick one
    const requestData: Record<string, unknown> = {
      title: `Account Request: ${getPlanName(selectedPlan.value)}`,
      description: `New account request for ${getPlanName(selectedPlan.value)}\n\nEmail: ${form.value.email}\nSelected Plan: ${selectedPlan.value}`,
      submitter_email: form.value.email,
      priority: 3,
      is_demo_request: 'true',
      requested_plan: selectedPlan.value
    }

    if (salesQueueId.value) {
      requestData.queue = salesQueueId.value
    }
    // If salesQueueId is null the backend will resolve the queue dynamically

    const response = await post<Record<string, unknown>, {
      success: boolean
      ticket_id: number
      auto_login_url: string
      message: string
      error?: string
      email_exists?: boolean
    }>('helpdesk/api/public/account-request/', requestData, { requireAuth: false })

    if (!response.success) {
      // Backend returned a structured error (e.g. email_exists)
      if (response.email_exists) {
        emailError.value = response.error || 'This email is already registered.'
      }
      errorMessage.value = response.error || 'Something went wrong. Please try again.'
      return
    }

    ticketId.value = response.ticket_id
    isSuccess.value = true
    emit('submitted', response.ticket_id)

    setTimeout(() => {
      window.location.href = response.auto_login_url
    }, 2000)

  } catch (error: any) {
    console.error('Failed to submit account request:', error)

    // Extract the most useful error message from the response
    const data = error?.response?.data
    if (data) {
      if (data.email_exists) {
        emailError.value = data.error || 'This email is already registered.'
        errorMessage.value = data.error || 'This email is already registered.'
      } else if (typeof data.error === 'string') {
        errorMessage.value = data.error
      } else if (typeof data.detail === 'string') {
        errorMessage.value = data.detail
      } else if (data.submitter_email) {
        errorMessage.value = Array.isArray(data.submitter_email)
          ? data.submitter_email.join(' ')
          : String(data.submitter_email)
      } else if (data.queue) {
        // Queue validation error — re-fetch queue and advise retry
        errorMessage.value = 'Could not assign a support queue. Please try again.'
        fetchSalesQueue()
      } else {
        errorMessage.value = 'Failed to submit your request. Please try again.'
      }
    } else {
      errorMessage.value = 'Network error. Please check your connection and try again.'
    }
  } finally {
    isSubmitting.value = false
  }
}

const resetForm = () => {
  selectedPlan.value = 'hcos-small-business-plan'
  form.value.email = ''
  isSuccess.value = false
  errorMessage.value = ''
  emailError.value = ''
  emailChecking.value = false
  closeFeatures()
}

const closeModal = () => {
  if (!isSubmitting.value) {
    visible.value = false
    resetForm()
    emit('close')
  }
}

const normalizeFeatures = (features: unknown): string[] => {
  if (Array.isArray(features)) {
    return features
      .map((f) => {
        if (typeof f === 'string') return f
        if (f && typeof f === 'object') {
          const obj = f as Record<string, unknown>
          const name = typeof obj.name === 'string' ? obj.name : ''
          const value = typeof obj.value === 'string' ? obj.value : ''
          if (value && name) return `${value} ${name}`
          if (name) return name
          if (value) return value
        }
        return ''
      })
      .filter(Boolean)
  }
  return []
}

const loadPlansFromBackend = async (): Promise<void> => {
  plansLoading.value = true
  try {
    const data = await get<unknown>('helpdesk/api/public/account-request/plans/', { requireAuth: false })

    const rawPlans = Array.isArray(data)
      ? data
      : (data && typeof data === 'object' && Array.isArray((data as any).plans))
        ? (data as any).plans
        : null

    if (!rawPlans) {
      plans.value = defaultPlans
      return
    }

    const mapped: SalesPlan[] = rawPlans
      .map((p: any) => {
        const slug = String(p.slug || p.key || p.plan_slug || '')
        if (!slug) return null

        const title = String(p.title || p.name || p.display_name || slug)
        const badge = typeof p.badge === 'string' ? p.badge : (p.recommended ? 'Popular' : undefined)

        const priceMain = typeof p.price_main === 'string'
          ? p.price_main
          : (typeof p.price === 'string' ? p.price : (typeof p.price_monthly === 'string' ? p.price_monthly : ''))

        const priceSub = typeof p.price_sub === 'string'
          ? p.price_sub
          : (typeof p.period === 'string' ? p.period : undefined)

        const features = normalizeFeatures(p.features || p.plan_features || p.display_features)
        const previewFeatures = features.slice(0, 4)

        return {
          slug,
          title,
          badge,
          priceMain: priceMain || slug,
          priceSub,
          previewFeatures: previewFeatures.length ? previewFeatures : ['See details'],
          features
        } as SalesPlan
      })
      .filter(Boolean) as SalesPlan[]

    plans.value = mapped.length ? mapped : defaultPlans
    if (!plans.value.some(p => p.slug === selectedPlan.value)) {
      selectedPlan.value = plans.value[0]?.slug || 'hcos-small-business-plan'
    }
  } catch (e) {
    plans.value = defaultPlans
  } finally {
    plansLoading.value = false
  }
}

// ── Initialise when modal opens ──
watch(() => props.isOpen, (val) => {
  visible.value = val
  if (val) {
    // Load both plans and queue in parallel
    loadPlansFromBackend()
    fetchSalesQueue()
  } else {
    resetForm()
  }
})
</script>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease-out, transform 0.2s ease-out;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
  transform: scale(0.98);
}

/* Optional: Custom scrollbar for webkit browsers for the plans area */
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: #cbd5e1;
  border-radius: 20px;
}
</style>