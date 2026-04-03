<template>
  <section id="features" class="features-section">
    <div class="container">
      <div class="section-header" data-aos="fade-up">
        <h2 class="section-title">Why Choose {{ brandingName }}?</h2>
        <p class="section-subtitle">
          A fully managed, tenant-isolated platform that lets hosting providers and commerce teams launch fast, automate billing, and keep payments flowing to their own processors.
        </p>
      </div>
      
      <div class="features-grid">
        <div class="feature-card" data-aos="fade-up" data-aos-delay="100">
          <div class="feature-icon">
            <Shield />
          </div>
          <h3>Tenant-Isolated SaaS</h3>
          <p>{{ brandingName }} is operated and secured by our team—no installs, no patching. Each vendor runs on isolated tenants with branded domains and dedicated resources.</p>
          <ul>
            <li>Zero-maintenance, {{ brandingName }}-managed platform</li>
            <li>Isolated tenants per vendor</li>
            <li>Branded portals and domains</li>
            <li>Secure auth baked-in end to end</li>
          </ul>
        </div>
        
        <div class="feature-card" data-aos="fade-up" data-aos-delay="200">
          <div class="feature-icon">
            <CreditCard />
          </div>
          <h3>Payments You Own</h3>
          <p>Connect Stripe, PayPal, CoinGate, or your own gateways—{{ brandingName }} manages checkout while funds land directly in your merchant accounts.</p>
          <ul>
            <li>Vendor-controlled processors</li>
            <li>{{ brandingName }}-managed checkout flows</li>
            <li>Processor-per-tenant isolation</li>
            <li>Tax-ready receipts and invoices</li>
          </ul>
        </div>
        
        <div class="feature-card" data-aos="fade-up" data-aos-delay="300">
          <div class="feature-icon">
            <Server />
          </div>
          <h3>Hosting Control Plane</h3>
          <p>Provision servers, expose graphical controls, and bill down to CPU, memory, and disk hour by hour or per plan.</p>
          <ul>
            <li>cPanel & Plesk automation</li>
            <li>Resource-based billing</li>
            <li>Provisioning & monitoring built-in</li>
            <li>Infrastructure UI for teams</li>
          </ul>
        </div>
        
        <div class="feature-card" data-aos="fade-up" data-aos-delay="400">
          <div class="feature-icon">
            <ShoppingCart />
          </div>
          <h3>Commerce & Catalog</h3>
          <p>Run full e-commerce alongside hosting—sell digital or physical products, manage stock, and bundle add-ons.</p>
          <ul>
            <li>Inventory and stock controls</li>
            <li>Bundles, add-ons, variants</li>
            <li>Digital & physical fulfillment</li>
            <li>Pricing rules by plan</li>
          </ul>
        </div>
        
        <div class="feature-card" data-aos="fade-up" data-aos-delay="500">
          <div class="feature-icon">
            <FileText />
          </div>
          <h3>Billing Automation</h3>
          <p>Hourly to annual cycles, automated invoicing, and plan-based {{ brandingName }} subscription during vendor onboarding.</p>
          <ul>
            <li>Usage or plan-based billing</li>
            <li>Multi-currency invoicing</li>
            <li>Dunning and renewals handled</li>
            <li>Revenue visibility per tenant</li>
          </ul>
        </div>
        
        <div class="feature-card" data-aos="fade-up" data-aos-delay="600">
          <div class="feature-icon">
            <Globe />
          </div>
          <h3>Support & Integrations</h3>
          <p>Live chat helpdesk, secure auth, and out-of-the-box connectors for payment gateways and control panels.</p>
          <ul>
            <li>Built-in helpdesk and chat</li>
            <li>Modern authentication stack</li>
            <li>PayPal, Stripe, CoinGate ready</li>
            <li>cPanel, Plesk, API-first tooling</li>
          </ul>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ShoppingCart, CreditCard, Server, Globe, FileText, Shield } from 'lucide-vue-next'
import { useBranding } from '@/services/branding'

const { businessName: brandingName } = useBranding()
</script>

<style scoped>
.features-section {
  padding: 6rem 0;
  background: hsl(222, 47%, 11%);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.section-header {
  text-align: center;
  margin-bottom: 4rem;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 1.75rem;
  margin-top: 3rem;
}

/* Glass card matching React feature cards */
.feature-card {
  background: rgba(27, 35, 51, 0.4);
  padding: 2.25rem;
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.07);
  backdrop-filter: blur(10px);
  transition: all 0.25s ease;
}

.feature-card:hover {
  transform: translateY(-6px);
  border-color: rgba(255, 255, 255, 0.15);
  background: rgba(27, 35, 51, 0.55);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
}

/* Icon container - white/10 bg matching React */
.feature-icon {
  width: 52px;
  height: 52px;
  background: rgba(255, 255, 255, 0.07);
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1.5rem;
  color: hsl(217, 91%, 68%);
  transition: background 0.2s ease;
}

.feature-card:hover .feature-icon {
  background: rgba(255, 255, 255, 0.12);
}

.feature-icon svg {
  width: 24px;
  height: 24px;
}

.feature-card h3 {
  font-family: var(--font-display);
  font-size: 1.25rem;
  font-weight: 700;
  color: white;
  margin-bottom: 0.75rem;
  letter-spacing: -0.01em;
}

.feature-card p {
  color: hsl(215, 20%, 65%);
  margin-bottom: 1.5rem;
  line-height: 1.65;
  font-size: 0.9375rem;
}

.feature-card ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.feature-card li {
  color: hsl(215, 20%, 72%);
  padding: 0.45rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
  position: relative;
  padding-left: 1.5rem;
  font-size: 0.875rem;
}

.feature-card li:last-child {
  border-bottom: none;
}

.feature-card li::before {
  content: "✓";
  position: absolute;
  left: 0;
  color: hsl(142, 69%, 50%);
  font-weight: 700;
  font-size: 0.8rem;
  top: 0.45rem;
}

@media (max-width: 768px) {
  .features-grid { grid-template-columns: 1fr; gap: 1.25rem; }
  .feature-card { padding: 1.75rem; }
}
</style>

