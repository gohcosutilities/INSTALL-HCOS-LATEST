<script setup lang="ts">
import { useBranding } from '@/services/branding'

const { businessName: brandingName } = useBranding()

const props = defineProps<{
  onOpenContactSales?: () => void
}>()

const handleScheduleDemo = () => {
  props.onOpenContactSales?.()
}
</script>

<template>
  <section class="cta-section">
    <div class="container">
      <div class="cta-content">
        <h2 class="cta-title">Ready to launch a tenant-isolated hosting business?</h2>
        <p class="cta-subtitle">
          We operate the platform, you own the payments and the servers. Book an onboarding session and see how {{ brandingName }} automates billing, control panels, and commerce in one place.
        </p>
        
        <button class="btn-demo" @click="handleScheduleDemo">Start Setup</button>

        <div class="cta-footer">
          Managed SaaS • Vendor-owned processors • Hourly to annual billing
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.cta-section {
  padding: 6rem 0;
  background: hsl(217, 33%, 13%);
  position: relative;
  overflow: hidden;
  border-top: 1px solid rgba(255,255,255,0.05);
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.cta-section::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse 80% 60% at 50% 100%, rgba(37,99,235,0.2) 0%, transparent 70%),
              radial-gradient(ellipse 60% 50% at 50% 0%, rgba(124,58,237,0.15) 0%, transparent 70%);
  pointer-events: none;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  position: relative;
  z-index: 2;
}

.cta-content {
  text-align: center;
  max-width: 800px;
  margin: 0 auto;
}

.cta-title {
  font-family: var(--font-display, 'Plus Jakarta Sans', sans-serif);
  font-size: 3rem;
  font-weight: 800;
  color: white;
  margin-bottom: 1.5rem;
  line-height: 1.2;
}

.cta-subtitle {
  font-size: 1.25rem;
  color: hsl(215, 20%, 70%);
  margin-bottom: 3rem;
  line-height: 1.6;
  max-width: 700px;
  margin-left: auto;
  margin-right: auto;
}

.btn-demo {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 1.1rem 2.75rem;
  font-size: 1.1rem;
  font-weight: 700;
  background: linear-gradient(135deg, hsl(217,91%,60%) 0%, hsl(262,83%,58%) 100%);
  color: white;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 8px 30px rgba(37,99,235,0.35);
  margin-bottom: 2rem;
}

.btn-demo:hover {
  transform: translateY(-3px);
  box-shadow: 0 14px 42px rgba(37,99,235,0.5);
}

.btn-demo:active {
  transform: translateY(0);
}

.cta-footer {
  color: hsl(215, 20%, 55%);
  font-size: 0.9rem;
  font-weight: 500;
}

@media (max-width: 768px) {
  .cta-section { padding: 4rem 0; }
  .cta-title { font-size: 2rem; }
  .cta-subtitle { font-size: 1.1rem; }
  .btn-demo { padding: 1rem 2rem; }
}
</style>
