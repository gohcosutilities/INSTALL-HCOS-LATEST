<template>
  <section id="billing" class="billing-section">
    <div class="container">
      <div class="billing-content">
        <div class="billing-text" data-aos="fade-right">
          <h2 class="section-title">Billing Built for Hosting and Commerce</h2>
          <p class="section-subtitle">
            Automate hourly, monthly, or annual cycles, charge for resources, and let every vendor keep control of their own payment processors while {{ brandingName }} collects its plan during onboarding.
          </p>
          
          <div class="billing-features">
            <div class="billing-feature">
              <div class="feature-icon">
                <Clock />
              </div>
              <div class="feature-content">
                <h4>Flexible Cycles</h4>
                <p>Hourly, usage-based, or subscription billing with prorates and automatic renewals.</p>
              </div>
            </div>
            
            <div class="billing-feature">
              <div class="feature-icon">
                <TrendingUp />
              </div>
              <div class="feature-content">
                <h4>Processor Freedom</h4>
                <p>Checkout runs on {{ brandingName }} while payouts go straight to each vendor's Stripe, PayPal, or CoinGate accounts.</p>
              </div>
            </div>
            
            <div class="billing-feature">
              <div class="feature-icon">
                <Shield />
              </div>
              <div class="feature-content">
                <h4>Tenant Isolation</h4>
                <p>Segregated billing data, secure authentication, and controlled access per business vendor.</p>
              </div>
            </div>
            
            <div class="billing-feature">
              <div class="feature-icon">
                <FileText />
              </div>
              <div class="feature-content">
                <h4>Smart Invoicing</h4>
                <p>Multi-currency invoices, automated taxes, dunning, and receipts that match each billing model.</p>
              </div>
            </div>
          </div>
        </div>
        
        <div class="billing-visual" data-aos="fade-left">
          <div class="dashboard-mockup">
            <div class="mockup-header">
              <div class="header-buttons">
                <span class="btn-dot red"></span>
                <span class="btn-dot yellow"></span>
                <span class="btn-dot green"></span>
              </div>
              <div class="header-title">{{ brandingName }} Billing Dashboard</div>
            </div>
            <div class="mockup-content">
              <div class="metric-cards">
                <div class="metric-card">
                  <div class="metric-value">96%</div>
                  <div class="metric-label">Invoices auto-sent</div>
                  <div class="metric-trend positive">↑ uptime billing</div>
                </div>
                <div class="metric-card">
                  <div class="metric-value">3 processors</div>
                  <div class="metric-label">Per-tenant payment stacks</div>
                  <div class="metric-trend positive">Stripe • PayPal • CoinGate</div>
                </div>
              </div>
              <div class="chart-placeholder">
                <div class="chart-bars">
                  <div class="bar" style="height: 60%"></div>
                  <div class="bar" style="height: 80%"></div>
                  <div class="bar" style="height: 45%"></div>
                  <div class="bar" style="height: 90%"></div>
                  <div class="bar" style="height: 70%"></div>
                  <div class="bar" style="height: 95%"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { Clock, TrendingUp, Shield, FileText } from 'lucide-vue-next'
import { useBranding } from '@/services/branding'

const { businessName: brandingName } = useBranding()
</script>

<style scoped>
.billing-section {
  padding: 6rem 0;
  background: hsl(217, 33%, 13%);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.billing-content {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4rem;
  align-items: center;
}

.billing-features {
  margin: 2rem 0;
}

.billing-feature {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.feature-icon {
  width: 44px;
  height: 44px;
  background: rgba(59, 130, 246, 0.12);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: hsl(217, 91%, 68%);
  flex-shrink: 0;
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.feature-icon svg {
  width: 20px;
  height: 20px;
}

.feature-content h4 {
  font-family: var(--font-display);
  font-size: 1rem;
  font-weight: 700;
  color: hsl(210, 40%, 95%);
  margin-bottom: 0.35rem;
}

.feature-content p {
  color: hsl(215, 20%, 62%);
  line-height: 1.55;
  font-size: 0.9rem;
}

/* Mockup dashboard — dark glass */
.dashboard-mockup {
  background: rgba(17, 25, 40, 0.8);
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.4);
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(8px);
}

.mockup-header {
  background: rgba(255, 255, 255, 0.04);
  padding: 1rem 1.25rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.07);
}

.header-buttons {
  display: flex;
  gap: 0.5rem;
}

.btn-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.btn-dot.red    { background: #ff5f56; }
.btn-dot.yellow { background: #ffbd2e; }
.btn-dot.green  { background: #27ca3f; }

.header-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: hsl(215, 20%, 65%);
}

.mockup-content {
  padding: 1.5rem;
}

.metric-cards {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.metric-card {
  background: rgba(255, 255, 255, 0.04);
  padding: 1rem;
  border-radius: 10px;
  border: 1px solid rgba(255, 255, 255, 0.07);
}

.metric-value {
  font-size: 1.4rem;
  font-weight: 700;
  color: hsl(217, 91%, 68%);
  margin-bottom: 0.25rem;
}

.metric-label {
  font-size: 0.75rem;
  color: hsl(215, 20%, 55%);
  margin-bottom: 0.5rem;
}

.metric-trend {
  font-size: 0.75rem;
  font-weight: 600;
}

.metric-trend.positive { color: hsl(142, 69%, 45%); }

.chart-placeholder {
  height: 120px;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 8px;
  padding: 1rem;
  display: flex;
  align-items: flex-end;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

.chart-bars {
  display: flex;
  align-items: flex-end;
  gap: 0.5rem;
  width: 100%;
  height: 100%;
}

.bar {
  background: linear-gradient(to top, hsl(217, 91%, 55%), hsl(262, 83%, 62%));
  border-radius: 3px 3px 0 0;
  flex: 1;
  min-height: 20%;
  animation: growBar 1s ease-out forwards;
  transform: scaleY(0);
  transform-origin: bottom;
}

@keyframes growBar { to { transform: scaleY(1); } }

.bar:nth-child(1) { animation-delay: 0.1s; }
.bar:nth-child(2) { animation-delay: 0.2s; }
.bar:nth-child(3) { animation-delay: 0.3s; }
.bar:nth-child(4) { animation-delay: 0.4s; }
.bar:nth-child(5) { animation-delay: 0.5s; }
.bar:nth-child(6) { animation-delay: 0.6s; }

@media (max-width: 768px) {
  .billing-content { grid-template-columns: 1fr; gap: 3rem; }
  .billing-visual { order: -1; }
}
</style>