<template>
  <div id="app">
    <Navigation :onOpenContactSales="openOnboarding" />
    <HeroSection :onOpenContactSales="openOnboarding" :onOpenDemo="openDemoRequest" />
    <FeaturesSection />
    <ExperienceSection />
    <BillingFeatures />
    <HostingFeatures />
    <TechStack />
  
    <CTASection :onOpenContactSales="openOnboarding" />
    <ContactSection :onOpenContactSales="openOnboarding" />
    <Footer />
    
    <!-- Contact Sales Modal -->
    <DemoRequestModal 
      v-model="isContactSalesOpen"
      @close="closeContactSales"
      @submitted="handleTicketSubmitted"
    />

    <ContactSalesNew
      :isOpen="isOnboardingOpen"
      @close="closeOnboarding"
      @submitted="handleOnboardingSubmitted"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import DemoRequest from './DemoRequest.vue'
import ExperienceSection from './ExperienceSection.vue'
import Navigation from '@/components/Navigation.vue'
import HeroSection from '@/components/HeroSection.vue'
import FeaturesSection from '@/components/FeaturesSection.vue'
import BillingFeatures from '@/components/BillingFeatures.vue'
import HostingFeatures from '@/components/HostingFeatures.vue'
import TechStack from '@/components/TechStack.vue'
import CTASection from '@/components/CTASection.vue'
import ContactSection from '@/components/ContactSection.vue'
import DemoRequestModal from '@/components/DemoRequestModal.vue'
import Footer from '@/components/Footer.vue'
import ContactSalesNew from '@/components/ContactSalesNew.vue'

// Contact Sales Modal State
const isContactSalesOpen = ref(false)
const isOnboardingOpen = ref(false)

const openDemoRequest = () => {
  isContactSalesOpen.value = true
}

const openOnboarding = () => {
  isOnboardingOpen.value = true
}

const closeContactSales = () => {
  isContactSalesOpen.value = false
}

const closeOnboarding = () => {
  isOnboardingOpen.value = false
}

const handleTicketSubmitted = (ticketId: number) => {
  console.log('Sales inquiry submitted with ticket ID:', ticketId)
  // You can add additional tracking or analytics here
}

const handleOnboardingSubmitted = (ticketId: number) => {
  console.log('Onboarding request submitted with ticket ID:', ticketId)
}
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap');

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --font-body: 'Inter', 'Segoe UI', sans-serif;
  --font-display: 'Plus Jakarta Sans', 'Inter', sans-serif;

  --primary-blue: #0e182b;
  --accent-dark-blue: #0f2740;
  --accent-teal: #3b82f6;
  --accent-amber: #f6a301;
  --white: #ffffff;
  --gray-50: #f6f7fb;
  --gray-100: #e9edf5;
  --gray-200: #d9dfeb;
  --gray-300: #c1c8d9;
  --gray-400: #9aa3b8;
  --gray-500: #7a849b;
  --gray-600: #5b6478;
  --gray-700: #3b4355;
  --gray-800: #232a38;
  --gray-900: #0c121e;
  --stripe-primary: #3b82f6;
  --stripe-primary-hover: #2563eb;
  --stripe-primary-light: rgba(59, 130, 246, 0.12);
}

body {
  font-family: var(--font-body);
  line-height: 1.6;
  color: hsl(210, 40%, 98%);
  background: hsl(222, 47%, 11%);
  overflow-x: hidden;
  letter-spacing: -0.01em;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.btn {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 14px 24px;
  border: 1px solid transparent;
  border-radius: 12px;
  font-weight: 700;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.25s ease;
  text-decoration: none;
  letter-spacing: -0.01em;
}

.btn-primary {
  background: linear-gradient(135deg, hsl(217,91%,60%) 0%, hsl(262,83%,58%) 100%);
  color: white;
  box-shadow: 0 8px 28px rgba(37,99,235,0.35);
}

.btn-primary:hover {
  transform: translateY(-3px);
  box-shadow: 0 14px 42px rgba(37,99,235,0.5);
}

.btn-secondary {
  background: rgba(255, 255, 255, 0.07);
  border-color: rgba(255, 255, 255, 0.15);
  color: white;
  backdrop-filter: blur(6px);
}

.btn-secondary:hover {
  transform: translateY(-3px);
  background: rgba(255, 255, 255, 0.12);
}

.btn-outline {
  background: transparent;
  border: 1.5px solid hsl(217,91%,60%);
  color: hsl(217,91%,65%);
}

.btn-outline:hover {
  background: hsl(217,91%,60%);
  color: white;
  transform: translateY(-3px);
}

.section-title {
  font-family: var(--font-display);
  font-size: 2.4rem;
  font-weight: 700;
  margin-bottom: 1rem;
  background: linear-gradient(135deg, hsl(217,91%,68%) 0%, hsl(262,83%,68%) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.section-subtitle {
  font-size: 1.1rem;
  color: hsl(215, 20%, 65%);
  margin-bottom: 3rem;
  max-width: 720px;
  margin-left: auto;
  margin-right: auto;
}

@media (max-width: 768px) {
  .section-title { font-size: 2rem; }
  .section-subtitle { font-size: 1.05rem; }
}
</style>