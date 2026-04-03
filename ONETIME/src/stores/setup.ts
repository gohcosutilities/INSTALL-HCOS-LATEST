import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { createDefaultConfig, SECTIONS, type DeploymentConfig, type SectionKey } from '@/types'

const API_BASE = import.meta.env.VITE_API_URL || ''

export const useSetupStore = defineStore('setup', () => {
  // ── State ──
  const config = ref<DeploymentConfig>(createDefaultConfig())
  const activeSection = ref<SectionKey>('deployment')
  const deploying = ref(false)
  const deployStatus = ref<{ phase: string; message: string; log: string[]; complete: boolean; error: boolean }>({
    phase: 'idle',
    message: '',
    log: [],
    complete: false,
    error: false,
  })

  // ── Computed ──
  const sections = computed(() => SECTIONS)

  /** Modal should be visible when deploying, OR when there is a result (error/complete) to show */
  const showDeployModal = computed(() => deploying.value || deployStatus.value.error || deployStatus.value.complete)

  const completedSections = computed(() => {
    const done: SectionKey[] = []
    // A section is "complete" if at least one required field has a value
    if (config.value.deployment.serverIp && config.value.deployment.githubUser) done.push('deployment')
    if (config.value.core.siteUrl) done.push('core')
    if (config.value.database.password) done.push('database')
    if (config.value.keycloak.clientSecret || config.value.keycloak.adminPassword) done.push('keycloak')
    if (config.value.email.username) done.push('email')
    if (config.value.redis.host) done.push('redis')
    if (config.value.celery.brokerUrl) done.push('celery')
    if (config.value.stripe.testPublicKey || config.value.stripe.livePublicKey) done.push('stripe')
    if (config.value.paypal.testClientId || config.value.paypal.liveClientId) done.push('paypal')
    if (config.value.oscar.shopName) done.push('oscar')
    if (config.value.security.allowedDomains.length > 0) done.push('security')
    if (config.value.logging.logstashHost) done.push('logging')
    done.push('helpdesk', 'invoicing', 'policies', 'chat') // always have defaults
    if (config.value.business.countryCode) done.push('business')
    if (config.value.aws.accessKeyId) done.push('aws')
    if (config.value.cloudflare.apiToken) done.push('cloudflare')
    if (config.value.ssl.letsencryptEmail) done.push('ssl')
    if (config.value.nginx.containerName) done.push('nginx')
    if (config.value.system.mainHostname) done.push('system')
    return done
  })

  // ── Actions ──
  function setSection(key: SectionKey) {
    activeSection.value = key
  }

  async function detectIp() {
    try {
      const res = await fetch(`${API_BASE}/api/detect-ip`)
      const data = await res.json()
      if (data.ip) config.value.deployment.serverIp = data.ip
    } catch { /* ignore */ }
  }

  async function submitDeploy() {
    deploying.value = true
    deployStatus.value = { phase: 'starting', message: 'Submitting configuration…', log: [], complete: false, error: false }
    console.log('[DEPLOY] Starting deployment…', { configKeys: Object.keys(config.value) })

    try {
      const res = await fetch(`${API_BASE}/api/deploy`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config.value),
      })
      console.log('[DEPLOY] POST /api/deploy response status:', res.status)

      if (!res.ok) {
        const text = await res.text()
        console.error('[DEPLOY] Server returned error:', res.status, text)
        deployStatus.value = { phase: 'error', message: `Server error ${res.status}: ${text}`, log: [`ERROR: HTTP ${res.status} - ${text}`], complete: false, error: true }
        deploying.value = false
        return
      }

      const data = await res.json()
      console.log('[DEPLOY] Response data:', data)

      if (data.error) {
        deployStatus.value = { phase: 'error', message: data.error, log: [`ERROR: ${data.error}`], complete: false, error: true }
        deploying.value = false
        return
      }
      // Start polling
      pollStatus()
    } catch (err: any) {
      console.error('[DEPLOY] Fetch error:', err)
      deployStatus.value = { phase: 'error', message: err.message, log: [`ERROR: ${err.message}`], complete: false, error: true }
      deploying.value = false
    }
  }

  let pollTimer: ReturnType<typeof setInterval> | null = null

  function pollStatus() {
    if (pollTimer) clearInterval(pollTimer)
    pollTimer = setInterval(async () => {
      try {
        const res = await fetch(`${API_BASE}/api/deploy/status`)
        const data = await res.json()
        console.log('[DEPLOY POLL]', data.phase, data.message, `logs:${data.log?.length}`, `error:${data.error}`, `complete:${data.complete}`)
        deployStatus.value = data
        if (data.complete || data.error) {
          // Stop polling but do NOT set deploying=false.
          // The modal stays visible so the user can read the error/success.
          // User must explicitly dismiss via the close button.
          if (pollTimer) clearInterval(pollTimer)
          pollTimer = null
          deploying.value = false
        }
      } catch (e) {
        console.warn('[DEPLOY POLL] fetch error (will retry):', e)
      }
    }, 2000)
  }

  /** Dismiss the deployment modal and reset status */
  function dismissDeploy() {
    if (pollTimer) { clearInterval(pollTimer); pollTimer = null }
    deploying.value = false
    deployStatus.value = { phase: 'idle', message: '', log: [], complete: false, error: false }
  }

  /** Export current config as JSON string */
  function exportConfig(): string {
    return JSON.stringify(config.value, null, 2)
  }

  /** Import config from a JSON object (partial merge supported) */
  function importConfig(json: Partial<DeploymentConfig>) {
    const merged = { ...createDefaultConfig() }
    for (const section of Object.keys(json) as (keyof DeploymentConfig)[]) {
      if (json[section] && typeof json[section] === 'object' && !Array.isArray(json[section])) {
        ;(merged as any)[section] = { ...(merged as any)[section], ...(json as any)[section] }
      } else if (json[section] !== undefined) {
        ;(merged as any)[section] = (json as any)[section]
      }
    }
    config.value = merged
  }

  return {
    config,
    activeSection,
    deploying,
    deployStatus,
    showDeployModal,
    sections,
    completedSections,
    setSection,
    detectIp,
    submitDeploy,
    dismissDeploy,
    exportConfig,
    importConfig,
  }
})
