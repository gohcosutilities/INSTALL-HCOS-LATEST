<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import TextInput from '@/components/fields/TextInput.vue'
import PasswordInput from '@/components/fields/PasswordInput.vue'
import TagInput from '@/components/fields/TagInput.vue'
import { ref } from 'vue'

const store = useSetupStore()
const c = store.config.deployment

// ── Domain Management ──
function addRootDomain() {
  c.rootDomains.push({ domain: '', cloudflareToken: '' })
}
function removeRootDomain(idx: number) {
  c.rootDomains.splice(idx, 1)
}

function addDomain(list: string[]) {
  list.push('')
}
function removeDomain(list: string[], idx: number) {
  list.splice(idx, 1)
}

function addRepository() {
  c.repositories.push({ url: '', folder: '', domain: '', type: 'frontend', container: 'onedash' })
}

function removeRepository(idx: number) {
  c.repositories.splice(idx, 1)
}

store.detectIp()
</script>

<template>
  <div class="section">
    <h2 class="section-title">🚀 Deployment Configuration</h2>
    <p class="section-desc">Server credentials, repositories, and domain mapping required by the deploy script.</p>

    <!-- Server IP -->
    <div class="card">
      <h3 class="card-title">Server</h3>
      <TextInput v-model="c.serverIp" label="Server Public IP" placeholder="e.g., 52.100.12.1" help-text="Auto-detected if possible. This IP is used for DNS A records." required />
      <button type="button" class="btn-secondary" @click="store.detectIp()">Auto-detect IP</button>
    </div>

    <!-- GitHub -->
    <div class="card">
      <h3 class="card-title">GitHub Credentials</h3>
      <p class="card-desc">GitHub expects a Token as password when cloning private repositories.</p>
      <TextInput v-model="c.githubUser" label="GitHub Username" placeholder="gohcosutilities" help-text="Your GitHub username (not email). Used for repo authentication with the token below." required />
      <PasswordInput v-model="c.githubToken" label="GitHub Token" placeholder="ghp_..." required />
    </div>

    <!-- SSL / Let's Encrypt -->
    <div class="card">
      <h3 class="card-title">SSL Certificate</h3>
      <TextInput v-model="c.letsencryptEmail" label="Let's Encrypt Email" type="email" placeholder="admin@example.com" help-text="Used for certificate notifications and account recovery." required />
    </div>

    <!-- Root Domains -->
    <div class="card">
      <h3 class="card-title">Root Domains & Cloudflare</h3>
      <p class="card-desc">Define your root domains (e.g., example.com) and their respective Cloudflare API tokens for DNS-01 SSL challenges.</p>
      <div v-for="(rd, idx) in c.rootDomains" :key="idx" class="repo-row">
        <div class="repo-header">
          <span class="repo-type-badge backend">Root Domain</span>
          <button type="button" class="btn-remove" @click="removeRootDomain(idx)">✕</button>
        </div>
        <TextInput v-model="rd.domain" label="Root Domain" placeholder="example.com" />
        <PasswordInput v-model="rd.cloudflareToken" label="Cloudflare API Token" placeholder="API token with DNS edit permissions" />
      </div>
      <button type="button" class="btn-secondary" @click="addRootDomain()">+ Add Root Domain</button>
    </div>

    <!-- API Domains -->
    <div class="card">
      <h3 class="card-title">API Domains (Backend)</h3>
      <p class="card-desc">Domains that will proxy to the Django backend service (e.g., api.example.com).</p>
      <div v-for="(_, idx) in c.apiDomains" :key="'api'+idx" class="fe-row">
        <div style="display: flex; gap: 10px; align-items: center;">
          <TextInput v-model="c.apiDomains[idx]" placeholder="api.example.com" style="flex: 1;" />
          <button type="button" class="btn-remove" @click="removeDomain(c.apiDomains, idx)">✕</button>
        </div>
      </div>
      <button type="button" class="btn-secondary" @click="addDomain(c.apiDomains)">+ Add API Domain</button>
    </div>

    <!-- Frontend Domains -->
    <div class="card">
      <h3 class="card-title">Frontend Domains</h3>
      <p class="card-desc">Domains that will proxy to the Vue3 frontend service (e.g., onedash.example.com).</p>
      <div v-for="(_, idx) in c.frontendDomains" :key="'fe'+idx" class="fe-row">
        <div style="display: flex; gap: 10px; align-items: center;">
          <TextInput v-model="c.frontendDomains[idx]" placeholder="onedash.example.com" style="flex: 1;" />
          <button type="button" class="btn-remove" @click="removeDomain(c.frontendDomains, idx)">✕</button>
        </div>
      </div>
      <button type="button" class="btn-secondary" @click="addDomain(c.frontendDomains)">+ Add Frontend Domain</button>
    </div>

    <!-- Keycloak Domains -->
    <div class="card">
      <h3 class="card-title">Keycloak Domains</h3>
      <p class="card-desc">Domains that will proxy to the Keycloak service (e.g., key.example.com).</p>
      <div v-for="(_, idx) in c.keycloakDomains" :key="'kc'+idx" class="fe-row">
        <div style="display: flex; gap: 10px; align-items: center;">
          <TextInput v-model="c.keycloakDomains[idx]" placeholder="key.example.com" style="flex: 1;" />
          <button type="button" class="btn-remove" @click="removeDomain(c.keycloakDomains, idx)">✕</button>
        </div>
      </div>
      <button type="button" class="btn-secondary" @click="addDomain(c.keycloakDomains)">+ Add Keycloak Domain</button>
    </div>

    <!-- Homepage Domains -->
    <div class="card">
      <h3 class="card-title">Homepage Domains</h3>
      <p class="card-desc">Domains that will proxy to the Homepage project (e.g., example.com).</p>
      <div v-for="(_, idx) in c.homepageDomains" :key="'hp'+idx" class="fe-row">
        <div style="display: flex; gap: 10px; align-items: center;">
          <TextInput v-model="c.homepageDomains[idx]" placeholder="example.com" style="flex: 1;" />
          <button type="button" class="btn-remove" @click="removeDomain(c.homepageDomains, idx)">✕</button>
        </div>
      </div>
      <button type="button" class="btn-secondary" @click="addDomain(c.homepageDomains)">+ Add Homepage Domain</button>
    </div>
    <!-- Gohcos / Hosting Homepage Domains -->
    <div class="card">
      <h3 class="card-title">Hosting Homepage Domains</h3>
      <p class="card-desc">Domains that will proxy to the Gohcos / Hosting Homepage project (e.g., gohcos.com).</p>
      <div v-for="(_, idx) in c.gohcosDomains" :key="'gh'+idx" class="fe-row">
        <div style="display: flex; gap: 10px; align-items: center;">
          <TextInput v-model="c.gohcosDomains[idx]" placeholder="gohcos.com" style="flex: 1;" />
          <button type="button" class="btn-remove" @click="removeDomain(c.gohcosDomains, idx)">×</button>
        </div>
      </div>
      <button type="button" class="btn-secondary" @click="addDomain(c.gohcosDomains)">+ Add Hosting Homepage Domain</button>
    </div>
    <!-- Repositories -->
    <div class="card">
      <h3 class="card-title">Repositories</h3>
      <p class="card-desc">Map each repository to a folder name & which domain it will serve.</p>

      <div v-for="(repo, idx) in c.repositories" :key="idx" class="repo-row">
        <div class="repo-header">
          <span class="repo-type-badge" :class="repo.type">{{ repo.type }}</span>
          <button v-if="c.repositories.length > 1" type="button" class="btn-remove" @click="removeRepository(idx)">✕</button>
        </div>
        <TextInput v-model="repo.url" label="Repository URL" placeholder="https://github.com/org/repo.git" />
        <TextInput v-model="repo.folder" label="Folder Name" placeholder="e.g., BACKEND-API-HCOM" />
        <TextInput v-model="repo.domain" label="Domain" placeholder="e.g., request.example.com" />
        <div class="field">
          <label class="field-label">Type</label>
          <select v-model="repo.type" class="field-select">
            <option value="backend">Backend (Django)</option>
            <option value="frontend">Frontend (Vue3 Dashboard)</option>
            <option value="homepage">Homepage</option>
            <option value="gohcos">Gohcos</option>
          </select>
        </div>
        <div class="field">
          <label class="field-label">Container</label>
          <select v-model="repo.container" class="field-select">
            <option value="backend">backend</option>
            <option value="onedash">onedash</option>
            <option value="homepage">homepage</option>
            <option value="demo">demo</option>
            <option value="gohcosweb">gohcosweb</option>
          </select>
        </div>
      </div>
      <button type="button" class="btn-secondary" @click="addRepository()">+ Add Repository</button>
    </div>
  </div>
</template>

<style scoped>
.section { display: flex; flex-direction: column; gap: 24px; }
.section-title { font-size: 22px; font-weight: 700; color: var(--text-heading); }
.section-desc { color: var(--text-muted); font-size: 14px; margin-top: -16px; }
.card { background: var(--bg-card); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; }
.card-title { font-size: 16px; font-weight: 600; color: var(--text-heading); margin-bottom: 8px; }
.card-desc { font-size: 13px; color: var(--text-muted); margin-bottom: 16px; }
.btn-secondary {
  padding: 8px 16px; background: transparent; border: 1px solid var(--border);
  border-radius: var(--radius); color: var(--primary); cursor: pointer; font-size: 13px;
  transition: all 0.2s;
}
.btn-secondary:hover { background: rgba(59,130,246,0.1); border-color: var(--primary); }
.btn-secondary.small { padding: 6px 12px; font-size: 12px; }
.btn-remove { background: none; border: none; color: var(--danger); cursor: pointer; font-size: 16px; }
.repo-row { border: 1px solid var(--border); border-radius: var(--radius); padding: 16px; margin-bottom: 12px; }
.repo-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.repo-type-badge {
  padding: 2px 10px; border-radius: 10px; font-size: 11px; font-weight: 600; text-transform: uppercase;
}
.repo-type-badge.backend { background: rgba(239,68,68,0.15); color: #f87171; }
.repo-type-badge.frontend { background: rgba(59,130,246,0.15); color: #60a5fa; }
.repo-type-badge.homepage { background: rgba(16,185,129,0.15); color: #34d399; }
.domain-block { border: 1px solid var(--border); border-radius: var(--radius); padding: 12px; margin-bottom: 12px; }
.domain-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.domain-header code { color: var(--primary); font-size: 14px; }
.subdomain-list { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }
.subdomain-add { display: flex; gap: 8px; }
.tag { display: inline-flex; align-items: center; gap: 4px; padding: 4px 10px; background: var(--primary); color: white; border-radius: 12px; font-size: 12px; }
.tag-remove { background: none; border: none; color: white; cursor: pointer; font-size: 14px; opacity: 0.7; }
.tag-remove:hover { opacity: 1; }
.fe-row { border: 1px solid var(--border); border-radius: var(--radius); padding: 12px; margin-bottom: 12px; }
.checkbox-row { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--text-muted); margin-bottom: 8px; cursor: pointer; }
.field { margin-bottom: 16px; }
.field-label { display: block; font-size: 13px; font-weight: 600; color: var(--text-muted); margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.5px; }
.field-select {
  width: 100%; padding: 10px 14px; background: var(--bg-input); border: 1px solid var(--border);
  border-radius: var(--radius); color: var(--text); font-size: 14px; cursor: pointer;
}
.field-input { width: 100%; padding: 10px 14px; background: var(--bg-input); border: 1px solid var(--border); border-radius: var(--radius); color: var(--text); font-size: 14px; }
.field-input.small { padding: 6px 10px; font-size: 13px; }
.field-input:focus, .field-select:focus { outline: none; border-color: var(--primary); }
</style>
