<template>
  <div>
    <div class="flex justify-between items-center mb-4">
      <h2 style="font-size:18px;font-weight:600;">Backup Schedules</h2>
      <button class="btn btn-primary" @click="showCreate = true">+ New Schedule</button>
    </div>

    <div v-if="loading" class="empty-state"><span class="spinner"></span></div>

    <div v-else-if="schedules.length === 0 && !showCreate" class="card empty-state">
      <p>No backup schedules configured yet.</p>
    </div>

    <!-- Create form -->
    <div v-if="showCreate" class="card">
      <h2>New Schedule</h2>
      <div class="form-group">
        <label>Backup Type</label>
        <select v-model="newSchedule.backup_type" class="form-control">
          <option value="full">Full</option>
          <option value="files">Files Only</option>
          <option value="database">Databases Only</option>
        </select>
      </div>
      <div class="form-group">
        <label>Frequency</label>
        <select v-model="newSchedule.frequency" class="form-control">
          <option value="daily">Daily</option>
          <option value="weekly">Weekly</option>
          <option value="monthly">Monthly</option>
        </select>
      </div>
      <div class="form-group">
        <label>Retention (number of backups to keep)</label>
        <input type="number" v-model.number="newSchedule.retention_count" min="1" max="365" class="form-control" />
      </div>
      <div class="form-group">
        <label>Storage</label>
        <select v-model="newSchedule.storage_backend" class="form-control">
          <option value="local">Local</option>
          <option value="s3">S3-Compatible</option>
        </select>
      </div>
      <div class="flex gap-2 mt-4">
        <button class="btn btn-primary" :disabled="creating" @click="create">
          {{ creating ? 'Creating…' : 'Create Schedule' }}
        </button>
        <button class="btn btn-outline" @click="showCreate = false">Cancel</button>
      </div>
    </div>

    <!-- Existing schedules -->
    <div v-if="schedules.length > 0" class="card" style="padding:0;overflow:hidden;">
      <table class="data-table">
        <thead>
          <tr>
            <th>Type</th>
            <th>Frequency</th>
            <th>Storage</th>
            <th>Keep</th>
            <th>Active</th>
            <th>Next Run</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in schedules" :key="s.id">
            <td>{{ s.backup_type }}</td>
            <td>{{ s.frequency }}</td>
            <td>{{ s.storage_backend }}</td>
            <td>{{ s.retention_count }}</td>
            <td>
              <span :class="s.is_active ? 'status-badge status-completed' : 'status-badge status-cancelled'">
                {{ s.is_active ? 'Active' : 'Paused' }}
              </span>
            </td>
            <td class="text-muted">{{ formatDate(s.next_run) }}</td>
            <td class="text-right flex gap-2" style="justify-content:flex-end;">
              <button
                class="btn btn-sm btn-outline"
                @click="toggle(s)"
              >
                {{ s.is_active ? 'Pause' : 'Resume' }}
              </button>
              <button class="btn btn-sm btn-danger" @click="remove(s.id)">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <p v-if="error" style="color:var(--danger);margin-top:12px;">{{ error }}</p>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import {
  listSchedules,
  createSchedule,
  updateSchedule,
  deleteSchedule,
  serverId,
  type BackupSchedule,
} from '@/api'

const route = useRoute()
const domain = route.params.domain as string

const schedules = ref<BackupSchedule[]>([])
const loading = ref(true)
const creating = ref(false)
const showCreate = ref(false)
const error = ref('')

const newSchedule = reactive({
  backup_type: 'full',
  frequency: 'daily',
  retention_count: 7,
  storage_backend: 'local',
})

async function load() {
  loading.value = true
  try {
    const { data } = await listSchedules({ domain })
    schedules.value = Array.isArray(data) ? data : (data as any).results ?? []
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

async function create() {
  if (!serverId) { error.value = 'Server ID not found.'; return }
  creating.value = true
  error.value = ''
  try {
    await createSchedule({
      server: Number(serverId),
      domain,
      ...newSchedule,
      is_active: true,
    })
    showCreate.value = false
    await load()
  } catch (e: any) {
    error.value = e.response?.data?.detail || e.message
  } finally {
    creating.value = false
  }
}

async function toggle(s: BackupSchedule) {
  try {
    await updateSchedule(s.id, { is_active: !s.is_active })
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

async function remove(id: number) {
  if (!confirm('Delete this schedule?')) return
  try {
    await deleteSchedule(id)
    await load()
  } catch (e: any) {
    error.value = e.message
  }
}

function formatDate(iso: string | null): string {
  if (!iso) return '—'
  return new Date(iso).toLocaleString()
}

onMounted(load)
</script>
