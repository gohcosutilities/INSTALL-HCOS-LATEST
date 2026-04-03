<template>
  <nav class="navbar" :class="{ scrolled: isScrolled }">
    <div class="container">
        <div class="nav-content">
          <div class="logo" @click="enterHome">
           
            <div class="logo-text">
              <h2>{{ brandingName }}</h2>
              
            </div>
          </div>
          
          <div class="nav-links" :class="{ active: mobileMenuOpen }">
            <a href="#features" @click="closeMobileMenu">Platform</a>
            <a href="#billing" @click="closeMobileMenu">Automation</a>
            <a href="#hosting" @click="closeMobileMenu">Control Plane</a>
            <a href="#technology" @click="closeMobileMenu">Connectors</a>
            <button class="demo-request-btn" @click="handleContact">Start Setup</button>
          </div>
          
          <button class="mobile-toggle" @click="toggleMobileMenu">
            <Menu v-if="!mobileMenuOpen" />
            <X v-else />
          </button>
        </div>
      </div>
    </nav>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { Menu, X } from 'lucide-vue-next'
import { useRouter } from 'vue-router'
import { useBranding } from '@/services/branding'

const router = useRouter()
const { businessName, initials } = useBranding()

// Computed references for template
const brandingName = businessName
const brandingInitials = initials

const props = defineProps<{
  onOpenContactSales?: () => void
}>()

const isScrolled = ref(false)
const mobileMenuOpen = ref(false)

const handleScroll = () => {
  isScrolled.value = window.scrollY > 50
}

const toggleMobileMenu = () => {
  mobileMenuOpen.value = !mobileMenuOpen.value
}

const closeMobileMenu = () => {
  mobileMenuOpen.value = false
}

const handleContact = () => {
  props.onOpenContactSales?.()
  closeMobileMenu()
}

//component methods
const enterHome = () => {
  router.push({ path: '/' })
}
onMounted(() => {
  window.addEventListener('scroll', handleScroll)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})
</script>

<style scoped>
.navbar {
  position: fixed;
  top: 0;
  width: 100%;
  z-index: 1000;
  background: rgba(13, 20, 36, 0.8);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  transition: all 0.3s ease;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.navbar.scrolled {
  background: rgba(13, 20, 36, 0.96);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}

.nav-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.logo-mark {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.1);
  display: grid;
  place-items: center;
  color: white;
  font-weight: 800;
  border: 1px solid rgba(255, 255, 255, 0.12);
}

.logo-text h2 {
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 800;
  color: white;
  margin: 0;
  letter-spacing: -0.02em;
}

.logo-text span {
  font-size: 0.75rem;
  color: var(--hcos-text-muted);
  font-weight: 500;
}

.nav-links {
  display: flex;
  align-items: center;
  gap: 1.75rem;
}

.nav-links a {
  text-decoration: none;
  color: var(--hcos-text-muted);
  font-size: 0.8125rem;
  font-weight: 600;
  transition: color 0.2s ease;
  letter-spacing: -0.01em;
}

.nav-links a:hover {
  color: white;
}

.demo-request-btn {
  padding: 8px 18px;
  background: white;
  color: #0d1117;
  border: none;
  border-radius: 8px;
  font-size: 0.8125rem;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.15s ease;
}

.demo-request-btn:hover {
  background: #f0f4f8;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(255, 255, 255, 0.15);
}

.mobile-toggle {
  display: none;
  background: none;
  border: none;
  cursor: pointer;
  color: var(--hcos-text-muted);
  padding: 4px;
}

.mobile-toggle:hover {
  color: white;
}

@media (max-width: 768px) {
  .mobile-toggle {
    display: block;
  }
  
  .nav-links {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background: rgba(13, 20, 36, 0.98);
    backdrop-filter: blur(20px);
    flex-direction: column;
    padding: 1.5rem 1.5rem 2rem;
    transform: translateY(-100%);
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s ease;
    border-top: 1px solid rgba(255, 255, 255, 0.06);
    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
    gap: 1.25rem;
  }
  
  .nav-links.active {
    transform: translateY(0);
    opacity: 1;
    visibility: visible;
  }
  
  .demo-request-btn {
    width: 100%;
  }
}
</style>