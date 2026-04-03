<template>
  <section id="technology" class="tech-section">
    <div class="container">
      <div class="section-header" data-aos="fade-up">
        <h2 class="section-title">Connectors That Ship with {{ brandingName }}</h2>
        <p class="section-subtitle">
          Payments stay on your rails, servers stay in your cloud, and {{ brandingName }} bridges everything with secure identity, helpdesk, and monitoring.
        </p>
      </div>
      
      <div class="tech-grid">
        <div class="tech-category" data-aos="fade-up" data-aos-delay="100">
          <div class="category-header">
            <Cloud class="category-icon" />
            <h3>Payment Rails & Identity</h3>
          </div>
          <div class="tech-items">
            <div class="tech-item">
              <div class="tech-logo stripe">Stripe</div>
              <span>Stripe Connect / Elements</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo paypal">PayPal</div>
              <span>PayPal & Braintree</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo coingate">CG</div>
              <span>CoinGate crypto payments</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo oauth">
                <Shield class="tech-icon" />
              </div>
              <span>OAuth2 / JWT authentication</span>
            </div>
          </div>
        </div>
        
        <div class="tech-category" data-aos="fade-up" data-aos-delay="200">
          <div class="category-header">
            <Code class="category-icon" />
            <h3>Hosting Automation</h3>
          </div>
          <div class="tech-items">
            <div class="tech-item">
              <div class="tech-logo cpanel">cP</div>
              <span>cPanel provisioning</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo plesk">Plesk</div>
              <span>Plesk automation</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo directadmin">DA</div>
              <span>DirectAdmin control</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo cloudlinux">CL</div>
              <span>CloudLinux isolation</span>
            </div>
          </div>
        </div>
        
        <div class="tech-category" data-aos="fade-up" data-aos-delay="300">
          <div class="category-header">
            <Database class="category-icon" />
            <h3>Commerce & Catalog</h3>
          </div>
          <div class="tech-items">
            <div class="tech-item">
              <div class="tech-logo catalog">CAT</div>
              <span>Products, bundles, add-ons</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo inventory">INV</div>
              <span>Inventory & stock records</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo digital">DIG</div>
              <span>Digital delivery workflows</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo shipping">
                <Layers class="tech-icon" />
              </div>
              <span>Shipping & tax rules</span>
            </div>
          </div>
        </div>
        
        <div class="tech-category" data-aos="fade-up" data-aos-delay="400">
          <div class="category-header">
            <Shield class="category-icon" />
            <h3>Support & Observability</h3>
          </div>
          <div class="tech-items">
            <div class="tech-item">
              <div class="tech-logo helpdesk">
                <HardDrive class="tech-icon" />
              </div>
              <span>Built-in helpdesk & chat</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo monitoring">
                <Activity class="tech-icon" />
              </div>
              <span>Prometheus metrics</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo ssl">SSL</div>
              <span>SSL/TLS everywhere</span>
            </div>
            <div class="tech-item">
              <div class="tech-logo backup">
                <HardDrive class="tech-icon" />
              </div>
              <span>Automated backups</span>
            </div>
          </div>
        </div>
      </div>
      
      <div class="architecture-diagram" data-aos="fade-up" data-aos-delay="500">
        <h3>Managed SaaS Architecture</h3>
        <div class="diagram">
          <div class="diagram-layer frontend">
            <h4>{{ brandingName }} Managed SaaS</h4>
            <p>{{ brandingName }} runs, patches, and secures the platform for every tenant.</p>
          </div>
          <div class="diagram-arrow">↓</div>
          <div class="diagram-layer api">
            <h4>Tenant Payment Rails</h4>
            <p>Per-tenant payment processors and identity flows.</p>
          </div>
          <div class="diagram-arrow">↓</div>
          <div class="diagram-layer services">
            <h4>Hosting & Commerce Services</h4>
            <p>Billing, hosting automation, catalog, helpdesk.</p>
          </div>
          <div class="diagram-arrow">↓</div>
          <div class="diagram-layer data">
            <h4>Vendor Assets & Data</h4>
            <p>Isolated tenant data, server connectors, product assets.</p>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { 
  Cloud, 
  Code, 
  Database, 
  Shield, 
  Layers, 
  Activity, 
  HardDrive 
} from 'lucide-vue-next'
import { useBranding } from '@/services/branding'

const { businessName: brandingName } = useBranding()
</script>

<style scoped>
.tech-section {
  padding: 6rem 0;
  background: hsl(217, 33%, 13%);
  position: relative;
  overflow: hidden;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.container { position: relative; z-index: 2; }

.section-header { text-align: center; margin-bottom: 4rem; }

.section-title { color: white; }
.section-subtitle { color: hsl(215,20%,65%); }

.tech-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.75rem;
  margin-bottom: 4rem;
}

.tech-category {
  background: rgba(27,35,51,0.45);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 20px;
  padding: 1.75rem;
  backdrop-filter: blur(10px);
  transition: all 0.25s ease;
}

.tech-category:hover {
  transform: translateY(-4px);
  background: rgba(27,35,51,0.65);
  border-color: rgba(59,130,246,0.3);
}

.category-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.category-icon { width: 26px; height: 26px; color: hsl(217,91%,65%); }

.category-header h3 {
  font-family: var(--font-display);
  font-size: 1.1rem;
  font-weight: 700;
  margin: 0;
  color: white;
}

.tech-items { display: flex; flex-direction: column; gap: 0.75rem; }

.tech-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.65rem 0.85rem;
  background: rgba(255,255,255,0.04);
  border-radius: 10px;
  border: 1px solid rgba(255,255,255,0.05);
  transition: all 0.2s ease;
  color: hsl(215,20%,70%);
  font-size: 0.875rem;
}

.tech-item:hover {
  background: rgba(255,255,255,0.08);
  transform: translateX(4px);
  border-color: rgba(59,130,246,0.2);
}

.tech-logo {
  width: 36px; height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 0.8rem;
  flex-shrink: 0;
}

.tech-logo.stripe      { background: hsl(199,89%,20%); color: hsl(199,89%,70%); }
.tech-logo.paypal      { background: hsl(214,78%,15%); color: hsl(214,78%,70%); }
.tech-logo.coingate    { background: hsl(220,50%,18%); color: hsl(217,91%,70%); }
.tech-logo.oauth       { background: hsl(222,40%,15%); color: hsl(215,20%,75%); }
.tech-logo.cpanel      { background: hsl(25,85%,20%); color: hsl(25,85%,70%); }
.tech-logo.plesk       { background: hsl(220,40%,14%); color: hsl(214,90%,70%); }
.tech-logo.directadmin { background: hsl(222,40%,14%); color: hsl(215,20%,70%); }
.tech-logo.cloudlinux  { background: hsl(214,60%,18%); color: hsl(214,78%,70%); }
.tech-logo.catalog     { background: hsl(222,40%,14%); color: hsl(215,20%,70%); }
.tech-logo.inventory   { background: hsl(142,50%,14%); color: hsl(142,69%,60%); }
.tech-logo.digital     { background: hsl(199,60%,14%); color: hsl(199,89%,70%); }
.tech-logo.shipping    { background: hsl(38,60%,15%); color: hsl(38,92%,65%); }
.tech-logo.helpdesk    { background: hsl(262,50%,18%); color: hsl(262,83%,72%); }
.tech-logo.monitoring  { background: hsl(15,70%,18%); color: hsl(15,80%,65%); }
.tech-logo.ssl         { background: hsl(199,70%,14%); color: hsl(199,89%,65%); }
.tech-logo.backup      { background: hsl(222,30%,15%); color: hsl(215,20%,65%); }

.tech-icon { width: 18px; height: 18px; }

.architecture-diagram {
  background: linear-gradient(135deg, rgba(37,99,235,0.15) 0%, rgba(124,58,237,0.15) 100%);
  border: 1px solid rgba(255,255,255,0.1);
  border-radius: 20px;
  padding: 3rem;
  text-align: center;
}

.architecture-diagram h3 {
  font-family: var(--font-display);
  font-size: 1.4rem;
  font-weight: 700;
  color: white;
  margin-bottom: 2rem;
}

.diagram { max-width: 600px; margin: 0 auto; }

.diagram-layer {
  background: rgba(255,255,255,0.07);
  border: 1px solid rgba(255,255,255,0.12);
  border-radius: 12px;
  padding: 1.25rem 1.5rem;
  margin-bottom: 0.75rem;
  transition: all 0.2s ease;
}

.diagram-layer:hover {
  background: rgba(255,255,255,0.1);
  transform: scale(1.01);
}

.diagram-layer h4 {
  font-family: var(--font-display);
  font-size: 1rem;
  font-weight: 700;
  margin-bottom: 0.4rem;
  color: hsl(217,91%,68%);
}

.diagram-layer p { color: hsl(215,20%,65%); margin: 0; font-size: 0.875rem; }

.diagram-arrow { font-size: 1.25rem; color: hsl(217,91%,60%); margin: 0.4rem 0; }

.frontend { border-color: hsl(199,89%,40%); }
.api      { border-color: hsl(142,69%,35%); }
.services { border-color: hsl(217,91%,50%); }
.data     { border-color: hsl(262,83%,55%); }

@media (max-width: 768px) {
  .tech-grid { grid-template-columns: 1fr; }
  .architecture-diagram { padding: 2rem; }
}
</style>