<template>
  <footer class="footer">
    <div class="container">
      <div class="footer-content">
        <div class="footer-brand">
          <div class="logo">
            <h3>{{ brandingNameWithIO }}</h3>
            <span>Hosting & Commerce Operating System</span>
          </div>
          <p class="brand-description">
            The next-generation billing and hosting management platform designed for modern businesses. Built with cutting-edge technology for unmatched performance and reliability.
          </p>
          <div class="social-links">
            <a href="#" class="social-link">
              <Twitter />
            </a>
            <a href="#" class="social-link">
              <Linkedin />
            </a>
            <a href="#" class="social-link">
              <Github />
            </a>
            <a href="#" class="social-link">
              <Youtube />
            </a>
          </div>
        </div>
        
        <div class="footer-links">
          <div class="link-group">
            <h4>Product</h4>
            <ul>
              <li><a href="#features">Features</a></li>
              <li><a href="#billing">Billing Automation</a></li>
              <li><a href="#hosting">Hosting Control</a></li>
              <li><a href="#technology">Connectors</a></li>
              <li><a href="#contact">Onboarding</a></li>
            </ul>
          </div>
          
          <div class="link-group">
            <h4>Solutions</h4>
            <ul>
              <li><a href="#hosting">Hosting Providers</a></li>
              <li><a href="#features">E-Commerce Teams</a></li>
              <li><a href="#features">Multi-tenant SaaS</a></li>
              <li><a href="#features">Resellers & MSPs</a></li>
              <li><a href="#contact">Enterprise</a></li>
            </ul>
          </div>
          
          <div class="link-group">
            <h4>Resources</h4>
            <ul>
              <li><a href="#documentation">Documentation</a></li>
              <li><a href="#api">API Reference</a></li>
              <li><a href="#guides">Setup Guides</a></li>
              <li><a href="#status">System Status</a></li>
              <li><a href="#contact">Contact</a></li>
            </ul>
          </div>
          
          <div class="link-group">
            <h4>Support</h4>
            <ul>
              <li><a href="#help">Helpdesk & Live Chat</a></li>
              <li><a href="#security">Security</a></li>
              <li><a href="#compliance">Compliance</a></li>
              <li><a href="#contact">Start Setup</a></li>
              <li><a href="#privacy">Privacy</a></li>
            </ul>
          </div>
        </div>
      </div>
      
      <div class="footer-bottom">
        <div class="footer-bottom-content">
          <div class="copyright">
            <p>&copy; {{ currentYear }} {{ brandingNameWithIO }}. All rights reserved.</p>
          </div>
          <div class="footer-bottom-links">
            <a href="#" @click.prevent="openLegalModal('privacy_policy')">Privacy Policy</a>
            <a href="#" @click.prevent="openLegalModal('terms_of_service')">Terms of Service</a>
            <a href="#" @click.prevent="openLegalModal('cookie_policy')">Cookie Policy</a>
            <a href="#" @click.prevent="openLegalModal('gdpr')">GDPR</a>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Legal Document Modal -->
    <LegalDocumentModal 
      v-model="showLegalModal" 
      :document-type="activeDocumentType"
    />
  </footer>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Twitter, Linkedin, Github, Youtube } from 'lucide-vue-next'
import LegalDocumentModal from './LegalDocumentModal.vue'
import type { LegalDocumentType } from '@/services/homepageContent'
import { useBranding } from '@/services/branding'

const { businessName } = useBranding()

// Computed branding name with .IO suffix
const brandingNameWithIO = computed(() => {
  const name = businessName.value || 'HCOS'
  return `${name}`
})

const currentYear = computed(() => new Date().getFullYear())

// Legal modal state
const showLegalModal = ref(false)
const activeDocumentType = ref<LegalDocumentType>('terms_of_service')

function openLegalModal(docType: LegalDocumentType) {
  activeDocumentType.value = docType
  showLegalModal.value = true
}
</script>

<style scoped>
.footer {
  background: hsl(218, 40%, 8%);
  color: white;
  position: relative;
  overflow: hidden;
  border-top: 1px solid rgba(255,255,255,0.07);
}

.footer::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse 70% 40% at 30% 100%, rgba(37,99,235,0.12) 0%, transparent 60%),
              radial-gradient(ellipse 50% 35% at 70% 0%, rgba(124,58,237,0.08) 0%, transparent 60%);
  pointer-events: none;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  position: relative;
  z-index: 2;
}

.footer-content {
  display: grid;
  grid-template-columns: 2fr 3fr;
  gap: 4rem;
  padding: 4rem 0 2rem;
}

.footer-brand .logo h3 {
  font-family: var(--font-display, 'Plus Jakarta Sans', sans-serif);
  font-size: 1.8rem;
  font-weight: 800;
  margin-bottom: 0.25rem;
  color: white;
}

.footer-brand .logo span {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.5);
  font-weight: 500;
}

.brand-description {
  color: rgba(255, 255, 255, 0.65);
  line-height: 1.6;
  margin: 1.5rem 0;
  max-width: 400px;
}

.social-links {
  display: flex;
  gap: 0.75rem;
}

.social-link {
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.07);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.6);
  transition: all 0.25s ease;
  text-decoration: none;
}

.social-link:hover {
  background: hsl(217, 91%, 60%);
  border-color: hsl(217, 91%, 60%);
  color: white;
  transform: translateY(-2px);
}

.social-link svg {
  width: 18px;
  height: 18px;
}

.footer-links {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 2rem;
}

.link-group h4 {
  font-size: 0.875rem;
  font-weight: 600;
  margin-bottom: 1rem;
  color: hsl(217, 91%, 68%);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.link-group ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.link-group ul li {
  margin-bottom: 0.6rem;
}

.link-group ul li a {
  color: rgba(255, 255, 255, 0.55);
  text-decoration: none;
  font-size: 0.9rem;
  transition: color 0.2s ease;
}

.link-group ul li a:hover {
  color: white;
}

.footer-bottom {
  border-top: 1px solid rgba(255, 255, 255, 0.07);
  padding: 2rem 0;
}

.footer-bottom-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.copyright p {
  color: rgba(255, 255, 255, 0.4);
  font-size: 0.875rem;
  margin: 0;
}

.footer-bottom-links {
  display: flex;
  gap: 2rem;
}

.footer-bottom-links a {
  color: rgba(255, 255, 255, 0.4);
  text-decoration: none;
  font-size: 0.875rem;
  transition: color 0.2s ease;
}

.footer-bottom-links a:hover {
  color: hsl(217, 91%, 68%);
}

@media (max-width: 768px) {
  .footer-content { grid-template-columns: 1fr; gap: 3rem; padding: 3rem 0 2rem; }
  .footer-links { grid-template-columns: repeat(2, 1fr); gap: 2rem; }
  .footer-bottom-content { flex-direction: column; gap: 1rem; text-align: center; }
  .footer-bottom-links { flex-wrap: wrap; justify-content: center; gap: 1rem; }
}

@media (max-width: 480px) {
  .footer-links { grid-template-columns: 1fr; }
  .social-links { justify-content: center; }
}
</style>