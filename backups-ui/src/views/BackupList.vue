<template>
  <div>
    <div class="flex justify-between items-center mb-4">
      <h2 style="font-size:18px;font-weight:600;">Backup History</h2>
      <router-link
        :to="`/websites/${domain}/backups/create`"
        class="btn btn-primary"
      >
        + New Backup
      </router-link>
    </div>

    <div v-if="loading" class="empty-state"><span class="spinner"></span></div>

    <div v-else-if="jobs.length === 0" class="card empty-state">
      <p>No backups yet. Create your first backup to get started.</p>
    </div>

    <div v-else class="card" style="padding:0;overflow:hidden;">
      <table class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Type</th>
            <th>Status</th>
            <th>Storage</th>
            <th>Size</th>
            <th>Created</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="job in jobs" :key="job.id">
            <td>#{{ job.id }}</td>
            <td>{{ job.backup_type_display || job.backup_type }}</td>
            <td>
              <span :class="'status-badge status-' + job.status">
                {{ job.status_display || job.status }}
              </span>
            </td>
            <td>{{ job.storage_backend_display || job.storage_backend }}</td>
            <td>{{ formatSize(job.size_bytes) }}</td>
            <td class="text-muted">{{ formatDate(job.created_at) }}</td>
            <td class="text-right">
              <button
                v-if="job.status === 'completed'"
                class="btn btn-sm btn-outline"
                @click="restore(job)"
              >
                Restore
              </button>
              <button
                v-if="job.status === 'pending'"
                class="btn btn-sm btn-danger"
                @click="cancel(job.id)"
              >
                Cancel
              </button>
              <button
                v-if="job.status === 'failed'"
                class="btn btn-sm btn-outline"
                @click="retry(job.id)"
              >
                Retry
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p v-if="error" style="color:var(--danger);margin-top:12px;">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  listBackupJobs,
  cancelBackupJob,
  retryBackupJob,
  createRestoreJob,
  serverId,
  type BackupJob,
} from '@/api'

const route = useRoute()
const router = useRouter()
const domain = route.params.domain as string

const jobs = ref<BackupJob[]>([])
const loading = ref(true)
const error = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const { data } = await listBackupJobs({ domain })
    jobs.value = Array.isArray(data) ? data : (data as any).results ?? []
  } catch (e: any) {
    error.value = e.response?.data?.message || e.message
  } finally {
    loading.value = false
  }
}

async function cancel(id: number) {
  try {
    await cancelBackupJob(id)
    await load()
  } catch (e: any) {
    error.value = e.response?.data?.message || e.message
  }
}

async function retry(id: number) {
  try {
    await retryBackupJob(id)
    await load()
  } catch (e: any) {
    error.value = e.response?.data?.message || e.message
  }
}

async function restore(job: BackupJob) {
  if (!confirm(`Restore domain "${domain}" from backup #${job.id}? This may overwrite current files and databases.`)) return
  try {
    await createRestoreJob({ backup: job.id, server: job.server, domain })
    router.push(`/websites/${domain}/backups/restores`)
  } catch (e: any) {
    error.value = e.response?.data?.message || e.message
  }
}

function formatSize(bytes: number | null): string {
  if (!bytes) return '—'
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + ' MB'
  return (bytes / 1024 / 1024 / 1024).toFixed(2) + ' GB'
}

function formatDate(iso: string): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleString()
}

onMounted(load)
</script>
