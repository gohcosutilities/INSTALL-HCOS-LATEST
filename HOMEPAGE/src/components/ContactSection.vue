<template>
  <section id="contact" class="contact-section">
    <div class="container">
      <div class="contact-content">
        <div class="contact-info" data-aos="fade-up">
          <h2 class="section-title">Let’s Take Your Success Even Further</h2>
          
          <div class="contact-features">
            <div class="contact-feature">
              <div class="feature-icon">
                <CheckCircle />
              </div>
              <div class="feature-text">
                  <h4>Managed SaaS</h4>
                  <p>{{ brandingName }} runs and patches the platform so you never install software.</p>
              </div>
            </div>
            
            <div class="contact-feature">
              <div class="feature-icon">
                <Users />
              </div>
              <div class="feature-text">
                  <h4>Vendor-Owned Payments</h4>
                  <p>Connect your processors; funds stay in your accounts.</p>
              </div>
            </div>
            
            <div class="contact-feature">
              <div class="feature-icon">
                <Zap />
              </div>
              <div class="feature-text">
                  <h4>Fast Onboarding</h4>
                  <p>Launch hosting packages and commerce catalogs in minutes.</p>
              </div>
            </div>
            
            <div class="contact-feature">
              <div class="feature-icon">
                <Shield />
              </div>
              <div class="feature-text">
                  <h4>Security by Design</h4>
                  <p>Modern authentication, tenant isolation, and encrypted flows.</p>
              </div>
            </div>
          </div>
          
          <button 
            @click="handleAccountRequest"
            class="btn-schedule-demo mr-4"
          >
             Explore the platform
          </button>

          
          <div class="contact-stats">
            <div class="stat">
              <div class="stat-number">0 installs</div>
              <div class="stat-label">Managed for every tenant</div>
            </div>
            <div class="stat">
              <div class="stat-number">3 rails</div>
              <div class="stat-label">Stripe • PayPal • CoinGate</div>
            </div>
            <div class="stat">
              <div class="stat-number">Hourly → Annual</div>
              <div class="stat-label">Billing models supported</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { CheckCircle, Users, Zap, Shield } from 'lucide-vue-next'
import { useBranding } from '@/services/branding'

const { businessName: brandingName } = useBranding()

const props = defineProps<{
  onOpenContactSales?: () => void
}>()

const handleAccountRequest = () => {
  props.onOpenContactSales?.()
}
</script>

<style scoped>
.contact-section {
  padding: 6rem 0;
  background: hsl(222, 47%, 11%);
  border-top: 1px solid rgba(255,255,255,0.05);
}

.contact-content {
  max-width: 900px;
  margin: 0 auto;
  text-align: center;
}

.contact-description {
  font-size: 1.1rem;
  color: hsl(215, 20%, 65%);
  margin-bottom: 3rem;
  line-height: 1.6;
}

.contact-features {
  margin-bottom: 3rem;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 2rem;
  text-align: left;
}

.contact-feature {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  background: rgba(27,35,51,0.4);
  border: 1px solid rgba(255,255,255,0.07);
  border-radius: 16px;
  padding: 1.25rem;
  transition: all 0.2s ease;
}

.contact-feature:hover {
  background: rgba(27,35,51,0.6);
  border-color: rgba(59,130,246,0.25);
}

.feature-icon {
  width: 48px;
  height: 48px;
  background: rgba(59, 130, 246, 0.15);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: hsl(217, 91%, 65%);
  flex-shrink: 0;
}

.feature-icon svg {
  width: 20px;
  height: 20px;
}

.feature-text h4 {
  font-size: 1rem;
  font-weight: 600;
  color: white;
  margin-bottom: 0.25rem;
}

.feature-text p {
  color: hsl(215, 20%, 65%);
  font-size: 0.9rem;
  line-height: 1.4;
  margin: 0;
}

.btn-schedule-demo {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 1rem 2.5rem;
  font-size: 1.1rem;
  font-weight: 700;
  background: linear-gradient(135deg, hsl(217,91%,60%) 0%, hsl(262,83%,58%) 100%);
  color: white;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 8px 28px rgba(37,99,235,0.35);
  margin-bottom: 3rem;
}

.btn-schedule-demo:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 40px rgba(37,99,235,0.5);
}

.btn-schedule-demo:active {
  transform: translateY(0);
}

.contact-stats {
  display: flex;
  gap: 3rem;
  padding-top: 2rem;
  border-top: 1px solid rgba(255,255,255,0.08);
  justify-content: center;
}

.stat { text-align: center; }

.stat-number {
  font-size: 1.8rem;
  font-weight: 700;
  color: hsl(217, 91%, 65%);
  margin-bottom: 0.25rem;
}

.stat-label {
  font-size: 0.9rem;
  color: hsl(215, 20%, 55%);
}

@media (max-width: 768px) {
  .contact-section { padding: 4rem 0; }
  .contact-features { grid-template-columns: 1fr; gap: 1.5rem; }
  .contact-stats { gap: 1.5rem; flex-wrap: wrap; }
  .btn-schedule-demo { padding: 1rem 2rem; font-size: 1.1rem; }
}
</style>