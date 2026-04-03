<script setup lang="ts">
import { useSetupStore } from '@/stores/setup'
import { computed, ref, onUpdated, nextTick, watch } from 'vue'
import Loading from '@/assets/loading.gif'
const store = useSetupStore()
const logContainer = ref<HTMLElement | null>(null)

const status = computed(() => store.deployStatus)
const phasePercentage = computed(() => {
  const phases: Record<string, number> = {
    idle: 0, starting: 5, writing_env: 10, cloudflare_creds: 15,
    cloning: 25, ssl: 40, dns: 50, nginx: 60,
    docker_compose: 70, docker_up: 80, migrations: 95, complete: 100, error: 0,
  }
  return phases[status.value.phase] ?? 50
})

onUpdated(() => {
  nextTick(() => {
    if (logContainer.value) {
      logContainer.value.scrollTop = logContainer.value.scrollHeight
    }
  })
})

// Debug: log every status change to the browser console
watch(status, (val) => {
  console.log('[DeploymentProgress] status changed:', val.phase, val.message, `error:${val.error}`, `complete:${val.complete}`, `logs:${val.log?.length}`)
}, { deep: true })

function dismiss() {
  store.dismissDeploy()
}
</script>

<template>
  <div class="overlay">
    <div class="modal">
      <div class="modal-header">
        <h2>{{ status.complete ? '✅ Deployment Complete' : status.error ? '❌ Deployment Failed' : '' }}<img v-if="!status.complete && !status.error" :src="Loading" alt="Loading..." /> Deploying…</h2>
        <button v-if="status.complete || status.error" class="close-btn" @click="dismiss">✕</button>
      </div>

      <!-- Progress bar -->
      <div class="progress-bar-track">
        <div
          class="progress-bar-fill"
          :class="{ error: status.error, complete: status.complete }"
          :style="{ width: (status.error ? 100 : phasePercentage) + '%' }"
        ></div>
      </div>
      <p class="phase-label">{{ status.phase.replace(/_/g, ' ').toUpperCase() }} — {{ status.message }}</p>

      <!-- Log viewer -->
      <div ref="logContainer" class="log-viewer">
        <div v-for="(line, i) in status.log" :key="i" class="log-line" :class="{ err: line.startsWith('ERROR') || line.startsWith('FAIL') }">{{ line }}</div>
        <div v-if="!status.complete && !status.error" class="log-line blink"><img :src="Loading" alt="Loading..." /></div>
      </div>

      <!-- Actions -->
      <div v-if="status.complete" class="actions">
        <p class="success-msg">All services are running. You can now access your application.</p>
      </div>
      <div v-if="status.error" class="actions">
        <button class="retry-btn" @click="store.submitDeploy()">Retry Deployment</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.overlay {
  position: fixed; inset: 0; background: rgba(0, 0, 0, 0.8); display: flex;
  align-items: center; justify-content: center; z-index: 1000; backdrop-filter: blur(4px);
}
.modal {
  background: var(--bg-card); border: 1px solid var(--border); border-radius: 12px;
  width: 90%; max-width: 720px; max-height: 80vh; display: flex; flex-direction: column; overflow: hidden;
}
.modal-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 20px 24px; border-bottom: 1px solid var(--border);
}
.modal-header h2 { font-size: 18px; font-weight: 700; color: var(--text-heading); margin: 0; }
.close-btn {
  background: none; border: none; color: var(--text-muted); font-size: 20px;
  cursor: pointer; padding: 4px 8px; border-radius: 4px;
}
.close-btn:hover { color: var(--text-heading); background: var(--border); }

.progress-bar-track {
  height: 4px; background: var(--border); margin: 0;
}
.progress-bar-fill {
  height: 100%; background: var(--primary); transition: width 0.6s ease;
}
.progress-bar-fill.error { background: #ef4444; }
.progress-bar-fill.complete { background: #22c55e; }

.phase-label {
  padding: 12px 24px; font-size: 12px; font-weight: 600; color: var(--text-muted);
  text-transform: uppercase; letter-spacing: 0.5px; border-bottom: 1px solid var(--border);
}

.log-viewer {
  flex: 1; overflow-y: auto; padding: 16px 24px; font-family: 'JetBrains Mono', 'Fira Code', monospace;
  font-size: 12px; line-height: 1.6; min-height: 200px; max-height: 400px; background: #0a0f1a;
}
.log-line { color: #94a3b8; white-space: pre-wrap; word-break: break-all; }
.log-line.err { color: #f87171; }
.blink { animation: blink 1s step-end infinite; color: var(--primary); }
@keyframes blink { 50% { opacity: 0; } }

.actions { padding: 16px 24px; border-top: 1px solid var(--border); text-align: center; }
.success-msg { color: #22c55e; font-weight: 500; margin: 0; }
.retry-btn {
  background: var(--primary); color: white; border: none; padding: 10px 24px;
  border-radius: 8px; font-weight: 600; cursor: pointer; font-size: 14px;
}
.retry-btn:hover { opacity: 0.9; }
</style>
