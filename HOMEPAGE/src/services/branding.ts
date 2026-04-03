/**
 * Branding Service for HOMEPAGE
 * 
 * Fetches system branding configuration from the backend API
 * and provides helper functions to replace HCOS references
 * with the business name set in System Settings.
 */
import { ref, computed, readonly } from 'vue'
import { get } from '@/services/api'

interface BrandingConfig {
  business_name: string
  initials: string
  site_url: string
  replacements: {
    HCOS: string
    Hcos: string
    hcos: string
    'HCOS.IO': string
    HC: string
    [key: string]: string
  }
}

// Reactive branding state
const brandingConfig = ref<BrandingConfig>({
  business_name: 'HCOS',
  initials: '',
  site_url: 'https://onedash.hcomos.com',
  replacements: {
    HCOS: 'HCOS',
    Hcos: 'Hcos',
    hcos: 'hcos',
    'HCOS.IO': 'HCOS.IO',
    HC: 'HC',
  }
})

const isLoaded = ref(false)
const isLoading = ref(false)
const error = ref<string | null>(null)

/**
 * Fetch branding configuration from the backend API
 */
async function fetchBranding(): Promise<void> {
  if (isLoaded.value || isLoading.value) return
  
  isLoading.value = true
  error.value = null
  
  try {
    const response = await get('/api/accounts/homepage/branding/')
    if (response) {
      brandingConfig.value = response as BrandingConfig
      isLoaded.value = true
      console.log('[Branding] Loaded branding config:', brandingConfig.value)
    }
  } catch (e) {
    console.warn('[Branding] Failed to load branding config, using defaults:', e)
    error.value = 'Failed to load branding configuration'
    // Keep default values
  } finally {
    isLoading.value = false
  }
}

/**
 * Get the business name (with fallback to HCOS)
 */
const businessName = computed(() => brandingConfig.value.business_name || 'HCOS')

/**
 * Get the initials for logos (with fallback to HC)
 */
const initials = computed(() => brandingConfig.value.initials || 'HC')

/**
 * Get the site URL
 */
const siteUrl = computed(() => brandingConfig.value.site_url || 'https://onedash.hcomos.com')

/**
 * Replace HCOS references in text with the business name
 * @param text - The text to process
 * @returns Text with HCOS references replaced
 */
function replaceHCOS(text: string): string {
  if (!text || !brandingConfig.value.replacements) return text
  
  let result = text
  const replacements = brandingConfig.value.replacements
  
  // Replace in order of specificity (longer patterns first)
  const patterns = Object.keys(replacements).sort((a, b) => b.length - a.length)
  
  for (const pattern of patterns) {
    const replacement = replacements[pattern]
    // Use case-sensitive replacement for exact matches
    result = result.split(pattern).join(replacement)
  }
  
  return result
}

/**
 * Composable hook for accessing branding in Vue components
 */
export function useBranding() {
  // Auto-fetch branding on first use
  if (!isLoaded.value && !isLoading.value) {
    fetchBranding()
  }
  
  return {
    // State
    config: readonly(brandingConfig),
    isLoaded: readonly(isLoaded),
    isLoading: readonly(isLoading),
    error: readonly(error),
    
    // Computed
    businessName,
    initials,
    siteUrl,
    
    // Methods
    fetchBranding,
    replaceHCOS,
  }
}

// Export for direct imports
export {
  fetchBranding,
  businessName,
  initials,
  siteUrl,
  replaceHCOS,
  brandingConfig,
}
