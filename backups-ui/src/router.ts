import { createRouter, createWebHistory } from 'vue-router'
import BackupList from '@/views/BackupList.vue'
import CreateBackup from '@/views/CreateBackup.vue'
import RestoreList from '@/views/RestoreList.vue'
import Schedules from '@/views/Schedules.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/websites/:domain/backups', name: 'backups', component: BackupList },
    { path: '/websites/:domain/backups/create', name: 'create-backup', component: CreateBackup },
    { path: '/websites/:domain/backups/restores', name: 'restores', component: RestoreList },
    { path: '/websites/:domain/backups/schedules', name: 'schedules', component: Schedules },
    // Catch-all → redirect to backup list
    { path: '/:pathMatch(.*)*', redirect: (to) => {
        const domain = to.params.pathMatch?.[0] || ''
        return `/websites/${domain}/backups`
      }
    },
  ],
})

export default router
