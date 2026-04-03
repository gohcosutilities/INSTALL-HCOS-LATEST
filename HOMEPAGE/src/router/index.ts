
import { createRouter, createWebHistory } from 'vue-router'


import { useUserContextStore } from '@/store/userContext'
import HomeView from '@/components/HomeView.vue'


const routes = [
  {
    path: '/',
    name: 'Home',
    component: HomeView
  },

]

const router = createRouter({
  history: createWebHistory(),
  routes
})



// Global navigation guard replicating former onMounted logic


export default router