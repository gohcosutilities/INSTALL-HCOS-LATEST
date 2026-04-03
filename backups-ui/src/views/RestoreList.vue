<template>
  <div>
    <h2 style="font-size:18px;font-weight:600;margin-bottom:16px;">Restore History</h2>

    <div v-if="loading" class="empty-state"><span class="spinner"></span></div>

    <div v-else-if="restores.length === 0" class="card empty-state">
      <p>No restore operations yet.</p>
    </div>

    <div v-else class="card" style="padding:0;overflow:hidden;">
      <table class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>From Backup</th>
            <th>Status</th>
            <th>Created</th>
            <th>Completed</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="r in restores" :key="r.id">
            <td>#{{ r.id }}</td>
            <td>#{{ r.backup }}</td>
            <td>
              <span :class="'status-badge status-' + r.status">
                {{ r.status_display || r.status }}
              </span>
            </td>
            <td class="text-muted">{{ formatDate(r.created_at) }}</td>
            <td class="text-muted">{{ formatDate(r.completed_at) }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <p v-if="error" style="color:var(--danger);margin-top:12px;">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { listRestoreJobs, type RestoreJob } from '@/api'

const route = useRoute()
const domain = route.params.domain as string
const restores = ref<RestoreJob[]>([])
const loading = ref(true)
const error = ref('')

async function load() {
  loading.value = true
  try {
    const { data } = await listRestoreJobs({ domain })
    restores.value = Array.isArray(data) ? data : (data as any).results ?? []
  } catch (e: any) {
    error.value = e.response?.data?.message || e.message
  } finally {
    loading.value = false
  }
}

function formatDate(iso: string | null): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleString()
}

onMounted(load)
</script>
