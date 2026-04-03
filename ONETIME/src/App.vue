<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import { SECTIONS, type SectionKey } from '@/types'
import { computed, onMounted, ref } from 'vue'

import DeploymentProgress from '@/components/DeploymentProgress.vue'
import DeploymentSection from '@/components/sections/DeploymentSection.vue'
import CoreSection from '@/components/sections/CoreSection.vue'
import DatabaseSection from '@/components/sections/DatabaseSection.vue'
import KeycloakSection from '@/components/sections/KeycloakSection.vue'
import EmailSection from '@/components/sections/EmailSection.vue'
import RedisSection from '@/components/sections/RedisSection.vue'
import CelerySection from '@/components/sections/CelerySection.vue'
import StripeSection from '@/components/sections/StripeSection.vue'
import PaypalSection from '@/components/sections/PaypalSection.vue'
import OscarSection from '@/components/sections/OscarSection.vue'
import SecuritySection from '@/components/sections/SecuritySection.vue'
import LoggingSection from '@/components/sections/LoggingSection.vue'
import HelpdeskSection from '@/components/sections/HelpdeskSection.vue'
import InvoicingSection from '@/components/sections/InvoicingSection.vue'
import BusinessSection from '@/components/sections/BusinessSection.vue'
import PoliciesSection from '@/components/sections/PoliciesSection.vue'
import AwsSection from '@/components/sections/AwsSection.vue'
import CloudflareSection from '@/components/sections/CloudflareSection.vue'
import SslSection from '@/components/sections/SslSection.vue'
import NginxSection from '@/components/sections/NginxSection.vue'
import SystemSection from '@/components/sections/SystemSection.vue'
import ChatSection from '@/components/sections/ChatSection.vue'

const store = useSetupStore()

const sectionComponents: Record<SectionKey, any> = {
  deployment: DeploymentSection,
  core: CoreSection,
  database: DatabaseSection,
  keycloak: KeycloakSection,
  email: EmailSection,
  redis: RedisSection,
  celery: CelerySection,
  stripe: StripeSection,
  paypal: PaypalSection,
  oscar: OscarSection,
  security: SecuritySection,
  logging: LoggingSection,
  helpdesk: HelpdeskSection,
  invoicing: InvoicingSection,
  business: BusinessSection,
  policies: PoliciesSection,
  aws: AwsSection,
  cloudflare: CloudflareSection,
  ssl: SslSection,
  nginx: NginxSection,
  system: SystemSection,
  chat: ChatSection,
}

const activeComponent = computed(() => sectionComponents[store.activeSection])
const progress = computed(() => {
  const total = SECTIONS.length
  const done = store.completedSections.length
  return Math.round((done / total) * 100)
})

const sectionIdx = computed(() => SECTIONS.findIndex(s => s.key === store.activeSection))

function prevSection() {
  if (sectionIdx.value > 0) store.setSection(SECTIONS[sectionIdx.value - 1].key)
}
function nextSection() {
  if (sectionIdx.value < SECTIONS.length - 1) store.setSection(SECTIONS[sectionIdx.value + 1].key)
}

onMounted(() => {
  store.detectIp()
})

// ── JSON Import / Export ──
const fileInput = ref<HTMLInputElement | null>(null)

function handleExport() {
  const json = store.exportConfig()
  const blob = new Blob([json], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'hcos-config.json'
  a.click()
  URL.revokeObjectURL(url)
}

function triggerImport() {
  fileInput.value?.click()
}

function handleImport(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => {
    try {
      const json = JSON.parse(reader.result as string)
      store.importConfig(json)
      console.log('[CONFIG] Imported config from', file.name)
    } catch (err) {
      alert('Invalid JSON file: ' + (err as Error).message)
    }
  }
  reader.readAsText(file)
  // Reset so the same file can be re-imported
  ;(e.target as HTMLInputElement).value = ''
}
</script>

<template>
  <div class="app-layout">
    <!-- Sidebar -->
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="logo">⚡</div>
        <div>
          <h1 class="brand">HCOS</h1>
          <p class="brand-sub">Deployment Setup</p>
        </div>
      </div>

      <!-- Progress ring -->
      <div class="progress-ring-wrap">
        <svg class="progress-ring" viewBox="0 0 80 80">
          <circle cx="40" cy="40" r="34" fill="none" stroke="var(--border)" stroke-width="4" />
          <circle cx="40" cy="40" r="34" fill="none" stroke="var(--primary)" stroke-width="4"
            stroke-linecap="round" :stroke-dasharray="213.6"
            :stroke-dashoffset="213.6 - (213.6 * progress) / 100"
            transform="rotate(-90 40 40)" />
        </svg>
        <span class="progress-text">{{ progress }}%</span>
      </div>

      <!-- JSON Import / Export -->
      <div class="config-actions">
        <button class="config-btn" @click="triggerImport" title="Import config JSON">📥 Import</button>
        <button class="config-btn" @click="handleExport" title="Export config JSON">📤 Export</button>
        <input ref="fileInput" type="file" accept=".json" style="display:none" @change="handleImport" />
      </div>

      <nav class="nav-sections">
        <button
          v-for="section in SECTIONS" :key="section.key"
          class="nav-item"
          :class="{
            active: store.activeSection === section.key,
            completed: store.completedSections.includes(section.key),
          }"
          @click="store.setSection(section.key)"
        >
          <span class="nav-icon">{{ section.icon }}</span>
          <span class="nav-label">{{ section.label }}</span>
          <span v-if="store.completedSections.includes(section.key)" class="check">✓</span>
        </button>
      </nav>

      <div class="sidebar-footer">
        <button class="deploy-btn" :disabled="store.deploying" @click="store.submitDeploy()">
          <template v-if="store.deploying">Deploying…</template>
          <template v-else>🚀 Deploy Now</template>
        </button>
      </div>
    </aside>

    <!-- Main Content -->
    <main class="main-content">
      <header class="content-header">
        <div class="breadcrumb">
          <span class="bc-home" @click="store.setSection('deployment')">Setup</span>
          <span class="bc-sep">›</span>
          <span class="bc-current">{{ SECTIONS[sectionIdx]?.label }}</span>
        </div>
        <div class="nav-arrows">
          <button class="arrow-btn" :disabled="sectionIdx === 0" @click="prevSection">← Prev</button>
          <span class="section-counter">{{ sectionIdx + 1 }} / {{ SECTIONS.length }}</span>
          <button class="arrow-btn" :disabled="sectionIdx === SECTIONS.length - 1" @click="nextSection">Next →</button>
        </div>
      </header>

      <div class="content-body">
        <component :is="activeComponent" />
      </div>

      <footer class="content-footer">
        <div class="footer-nav">
          <button v-if="sectionIdx > 0" class="footer-btn secondary" @click="prevSection">← Previous</button>
          <div class="spacer"></div>
          <button v-if="sectionIdx < SECTIONS.length - 1" class="footer-btn primary" @click="nextSection">Next Section →</button>
          <button v-else class="footer-btn deploy" :disabled="store.deploying" @click="store.submitDeploy()">🚀 Deploy Now</button>
        </div>
      </footer>
    </main>

    <!-- Deployment progress overlay (stays visible for error/complete states) -->
    <DeploymentProgress v-if="store.showDeployModal" />
  </div>
</template>

<style>
/* CSS Variables */
:root {
  --bg: #0f172a;
  --bg-card: #1e293b;
  --bg-sidebar: #0b1120;
  --border: #334155;
  --primary: #3b82f6;
  --primary-hover: #2563eb;
  --text-heading: #f1f5f9;
  --text-body: #cbd5e1;
  --text-muted: #64748b;
  --success: #22c55e;
  --danger: #ef4444;
  --warning: #f59e0b;
  --radius: 8px;
}

*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

html, body, #app {
  height: 100%; width: 100%; overflow: hidden;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: var(--bg); color: var(--text-body);
}

input, select, textarea, button { font-family: inherit; }

::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: #475569; }
</style>

<style scoped>
.app-layout {
  display: flex; height: 100vh; width: 100vw; overflow: hidden;
}

/* ── Sidebar ── */
.sidebar {
  width: 260px; min-width: 260px; background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  display: flex; flex-direction: column; overflow: hidden;
}
.sidebar-header {
  display: flex; align-items: center; gap: 12px;
  padding: 20px 16px; border-bottom: 1px solid var(--border);
}
.logo {
  width: 40px; height: 40px; border-radius: 10px;
  background: linear-gradient(135deg, var(--primary), #8b5cf6);
  display: flex; align-items: center; justify-content: center;
  font-size: 20px; flex-shrink: 0;
}
.brand { font-size: 18px; font-weight: 800; color: var(--text-heading); line-height: 1; }
.brand-sub { font-size: 11px; color: var(--text-muted); margin-top: 2px; }

.progress-ring-wrap {
  position: relative; width: 80px; height: 80px; margin: 16px auto;
}
.progress-ring { width: 80px; height: 80px; }
.progress-ring circle { transition: stroke-dashoffset 0.6s ease; }
.progress-text {
  position: absolute; inset: 0; display: flex; align-items: center; justify-content: center;
  font-size: 14px; font-weight: 700; color: var(--text-heading);
}

.config-actions {
  display: flex; gap: 6px; padding: 0 12px 12px; justify-content: center;
}
.config-btn {
  flex: 1; padding: 6px 10px; border: 1px solid var(--border); border-radius: 6px;
  background: transparent; color: var(--text-muted); cursor: pointer;
  font-size: 11px; font-weight: 600; transition: all 0.15s; text-align: center;
}
.config-btn:hover { border-color: var(--primary); color: var(--primary); background: rgba(59, 130, 246, 0.08); }

.nav-sections {
  flex: 1; overflow-y: auto; padding: 8px;
}
.nav-item {
  display: flex; align-items: center; gap: 10px; width: 100%;
  padding: 8px 12px; border: none; background: transparent;
  color: var(--text-muted); cursor: pointer; border-radius: 6px;
  font-size: 13px; text-align: left; transition: all 0.15s;
}
.nav-item:hover { background: rgba(59, 130, 246, 0.08); color: var(--text-body); }
.nav-item.active { background: rgba(59, 130, 246, 0.15); color: var(--primary); font-weight: 600; }
.nav-item.completed .nav-label { color: var(--text-body); }
.nav-icon { font-size: 16px; width: 22px; text-align: center; flex-shrink: 0; }
.nav-label { flex: 1; }
.check { color: var(--success); font-size: 12px; font-weight: 700; }

.sidebar-footer { padding: 16px; border-top: 1px solid var(--border); }
.deploy-btn {
  width: 100%; padding: 12px; border: none; border-radius: 8px;
  background: linear-gradient(135deg, var(--primary), #8b5cf6);
  color: white; font-size: 14px; font-weight: 700; cursor: pointer;
  transition: opacity 0.2s;
}
.deploy-btn:hover:not(:disabled) { opacity: 0.9; }
.deploy-btn:disabled { opacity: 0.5; cursor: not-allowed; }

/* ── Main Content ── */
.main-content {
  flex: 1; display: flex; flex-direction: column; overflow: hidden;
}

.content-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 16px 32px; border-bottom: 1px solid var(--border);
  background: var(--bg); flex-shrink: 0;
}
.breadcrumb { display: flex; align-items: center; gap: 8px; font-size: 13px; }
.bc-home { color: var(--text-muted); cursor: pointer; }
.bc-home:hover { color: var(--primary); }
.bc-sep { color: var(--border); }
.bc-current { color: var(--text-heading); font-weight: 600; }

.nav-arrows { display: flex; align-items: center; gap: 12px; }
.arrow-btn {
  padding: 6px 14px; border: 1px solid var(--border); border-radius: 6px;
  background: transparent; color: var(--text-body); cursor: pointer;
  font-size: 12px; transition: all 0.15s;
}
.arrow-btn:hover:not(:disabled) { border-color: var(--primary); color: var(--primary); }
.arrow-btn:disabled { opacity: 0.3; cursor: not-allowed; }
.section-counter { font-size: 12px; color: var(--text-muted); font-weight: 600; }

.content-body {
  flex: 1; overflow-y: auto; padding: 32px;
}

.content-footer {
  border-top: 1px solid var(--border); padding: 16px 32px;
  background: var(--bg); flex-shrink: 0;
}
.footer-nav { display: flex; align-items: center; }
.spacer { flex: 1; }
.footer-btn {
  padding: 10px 24px; border: none; border-radius: 8px;
  font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s;
}
.footer-btn.secondary {
  background: transparent; border: 1px solid var(--border); color: var(--text-body);
}
.footer-btn.secondary:hover { border-color: var(--primary); color: var(--primary); }
.footer-btn.primary { background: var(--primary); color: white; }
.footer-btn.primary:hover { background: var(--primary-hover); }
.footer-btn.deploy {
  background: linear-gradient(135deg, var(--primary), #8b5cf6); color: white;
}
.footer-btn.deploy:hover:not(:disabled) { opacity: 0.9; }
.footer-btn.deploy:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
