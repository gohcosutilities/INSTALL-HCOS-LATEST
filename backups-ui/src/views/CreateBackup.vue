<template>
  <div class="card">
    <h2>Create New Backup</h2>

    <div class="form-group">
      <label>Backup Type</label>
      <select v-model="form.backup_type" class="form-control">
        <option value="full">Full (Files + Databases)</option>
        <option value="files">Files Only</option>
        <option value="database">Databases Only</option>
      </select>
    </div>

    <div class="form-group">
      <label>Storage</label>
      <select v-model="form.storage_backend" class="form-control">
        <option value="local">Local (Server Disk)</option>
        <option value="s3">S3-Compatible</option>
      </select>
    </div>

    <!-- Database selection -->
    <div v-if="form.backup_type !== 'files'" class="form-group">
      <label>Databases</label>
      <div v-if="dbLoading" class="text-muted"><span class="spinner"></span> Loading databases…</div>
      <ul v-else class="check-list">
        <li v-if="databases.length === 0" class="text-muted">No databases found for this domain.</li>
        <li v-for="db in databases" :key="db">
          <label>
            <input type="checkbox" :value="db" v-model="form.selected_databases" />
            {{ db }}
          </label>
        </li>
      </ul>
      <p class="text-muted mt-2">Leave all unchecked to backup all databases.</p>
    </div>

    <!-- File path selection -->
    <div v-if="form.backup_type !== 'database'" class="form-group">
      <label>File Paths (optional — leave empty for full document root)</label>
      <div v-if="fileLoading" class="text-muted"><span class="spinner"></span> Loading files…</div>
      <ul v-else class="check-list">
        <li v-for="entry in fileEntries" :key="entry.path">
          <label>
            <input type="checkbox" :value="entry.path" v-model="form.selected_paths" />
            {{ entry.is_dir ? '📁' : '📄' }} {{ entry.name }}
            <span v-if="!entry.is_dir" class="text-muted">({{ formatSize(entry.size) }})</span>
          </label>
        </li>
      </ul>
    </div>

    <div class="flex gap-2 mt-4">
      <button class="btn btn-primary" :disabled="submitting" @click="submit">
        <span v-if="submitting" class="spinner"></span>
        {{ submitting ? 'Creating…' : 'Start Backup' }}
      </button>
      <router-link :to="`/websites/${domain}/backups`" class="btn btn-outline">Cancel</router-link>
    </div>

    <p v-if="error" style="color:var(--danger);margin-top:12px;">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  createBackupJob,
  listDomainDatabases,
  listDomainFiles,
  serverId,
} from '@/api'

const route = useRoute()
const router = useRouter()
const domain = route.params.domain as string

const form = reactive({
  backup_type: 'full',
  storage_backend: 'local',
  selected_databases: [] as string[],
  selected_paths: [] as string[],
})

const databases = ref<string[]>([])
const fileEntries = ref<{ name: string; path: string; is_dir: boolean; size: number }[]>([])
const dbLoading = ref(false)
const fileLoading = ref(false)
const submitting = ref(false)
const error = ref('')

async function loadDatabases() {
  if (!serverId) return
  dbLoading.value = true
  try {
    const { data } = await listDomainDatabases(serverId, domain)
    databases.value = data.databases || []
  } catch { /* ignore */ }
  finally { dbLoading.value = false }
}

async function loadFiles() {
  if (!serverId) return
  fileLoading.value = true
  try {
    const { data } = await listDomainFiles(serverId, domain)
    fileEntries.value = data.entries || []
  } catch { /* ignore */ }
  finally { fileLoading.value = false }
}

async function submit() {
  if (!serverId) {
    error.value = 'Server ID not found. Please reload the page.'
    return
  }
  submitting.value = true
  error.value = ''
  try {
    await createBackupJob({
      server: Number(serverId),
      domain,
      backup_type: form.backup_type,
      storage_backend: form.storage_backend,
      selected_paths: form.selected_paths.length ? form.selected_paths : undefined,
      selected_databases: form.selected_databases.length ? form.selected_databases : undefined,
    })
    router.push(`/websites/${domain}/backups`)
  } catch (e: any) {
    error.value = e.response?.data?.detail || e.response?.data?.message || e.message
  } finally {
    submitting.value = false
  }
}

function formatSize(bytes: number): string {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / 1024 / 1024).toFixed(1) + ' MB'
}

onMounted(() => {
  loadDatabases()
  loadFiles()
})
</script>
