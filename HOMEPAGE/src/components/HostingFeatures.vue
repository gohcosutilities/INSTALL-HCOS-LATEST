<template>
  <section id="hosting" class="hosting-section">
    <div class="container">
      <div class="section-header" data-aos="fade-up">
        <h2 class="section-title">Hosting Control Without the Overhead</h2>
        <p class="section-subtitle">
          Give every vendor an isolated control plane with automated provisioning, hourly resource billing, and graphical interfaces your teams and customers can trust.
        </p>
      </div>
      
      <div class="hosting-grid">
        <div class="hosting-feature" data-aos="fade-up" data-aos-delay="100">
          <div class="feature-visual">
            <div class="server-rack">
              <div class="server-unit active">
                <div class="server-lights">
                  <span class="light green"></span>
                  <span class="light green"></span>
                  <span class="light amber"></span>
                </div>
                <div class="server-info">
                  <div class="server-name">Web Server 01</div>
                  <div class="server-status">98% CPU • 4.2GB RAM</div>
                </div>
              </div>
              <div class="server-unit">
                <div class="server-lights">
                  <span class="light green"></span>
                  <span class="light green"></span>
                  <span class="light green"></span>
                </div>
                <div class="server-info">
                  <div class="server-name">DB Server 01</div>
                  <div class="server-status">45% CPU • 2.1GB RAM</div>
                </div>
              </div>
            </div>
          </div>
          <div class="feature-content">
            <h3>Server Automation</h3>
            <p>Provision and visualize servers automatically; {{ brandingName }} keeps usage flowing into billing while surfaces live health.</p>
            <ul>
              <li>Automated provisioning</li>
              <li>Real-time monitoring</li>
              <li>Performance alerts</li>
              <li>Operator and customer views</li>
            </ul>
          </div>
        </div>
        
        <div class="hosting-feature" data-aos="fade-up" data-aos-delay="200">
          <div class="feature-visual">
            <div class="control-panel">
              <div class="panel-header">
                <div class="panel-logo">cPanel</div>
                <div class="panel-user">admin@{{ brandingDomain }}</div>
              </div>
              <div class="panel-grid">
                <div class="panel-item">
                  <Database class="panel-icon" />
                  <span>Databases</span>
                </div>
                <div class="panel-item">
                  <Mail class="panel-icon" />
                  <span>Email</span>
                </div>
                <div class="panel-item">
                  <FileText class="panel-icon" />
                  <span>Files</span>
                </div>
                <div class="panel-item">
                  <BarChart class="panel-icon" />
                  <span>Metrics</span>
                </div>
              </div>
            </div>
          </div>
          <div class="feature-content">
            <h3>Control Panel Integration</h3>
            <p>Connect cPanel, Plesk, and DirectAdmin so vendors manage sites and mail from a single UI.</p>
            <ul>
              <li>cPanel integration</li>
              <li>Plesk compatibility</li>
              <li>DirectAdmin support</li>
              <li>Custom APIs</li>
            </ul>
          </div>
        </div>
        
        <div class="hosting-feature" data-aos="fade-up" data-aos-delay="300">
          <div class="feature-visual">
            <div class="cloudlinux-panel">
              <div class="cl-header">
                <div class="cl-logo">CloudLinux</div>
                <div class="cl-status active">ACTIVE</div>
              </div>
              <div class="resource-meters">
                <div class="resource-meter">
                  <div class="meter-label">CPU</div>
                  <div class="meter-bar">
                    <div class="meter-fill cpu" style="width: 65%"></div>
                  </div>
                  <div class="meter-value">65%</div>
                </div>
                <div class="resource-meter">
                  <div class="meter-label">Memory</div>
                  <div class="meter-bar">
                    <div class="meter-fill memory" style="width: 45%"></div>
                  </div>
                  <div class="meter-value">45%</div>
                </div>
                <div class="resource-meter">
                  <div class="meter-label">I/O</div>
                  <div class="meter-bar">
                    <div class="meter-fill io" style="width: 30%"></div>
                  </div>
                  <div class="meter-value">30%</div>
                </div>
              </div>
            </div>
          </div>
          <div class="feature-content">
            <h3>Resource Billing & Safeguards</h3>
            <p>Map CPU, memory, and I/O limits to hourly or plan charges while CloudLinux isolation protects every tenant.</p>
            <ul>
              <li>Resource limiting</li>
              <li>Account isolation</li>
              <li>Runtime version control</li>
              <li>Hourly or plan-based billing</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { Database, Mail, FileText, BarChart } from 'lucide-vue-next'
import { useBranding } from '@/services/branding'
import { computed } from 'vue'

const { businessName: brandingName, siteUrl } = useBranding()
const brandingDomain = computed(() => {
  try {
    return new URL(siteUrl.value).hostname
  } catch {
    return 'hcomos.com'
  }
})
</script>

<style scoped>
.hosting-section {
  padding: 6rem 0;
  background: hsl(222, 47%, 11%);
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
}

.section-header {
  text-align: center;
  margin-bottom: 4rem;
}

.hosting-grid {
  display: grid;
  gap: 3rem;
}

.hosting-feature {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 3rem;
  align-items: center;
  padding: 2rem 0;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.hosting-feature:last-child { border-bottom: none; }

.hosting-feature:nth-child(even) .feature-visual { order: 2; }
.hosting-feature:nth-child(even) .feature-content { order: 1; }

.feature-visual {
  display: flex;
  justify-content: center;
}

.feature-content h3 {
  font-family: var(--font-display);
  font-size: 1.4rem;
  font-weight: 700;
  color: white;
  margin-bottom: 0.75rem;
}

.feature-content p {
  color: hsl(215, 20%, 65%);
  line-height: 1.65;
  margin-bottom: 1rem;
}

.feature-content ul {
  list-style: none;
  padding: 0;
}

.feature-content li {
  color: hsl(215, 20%, 70%);
  padding: 0.4rem 0;
  padding-left: 1.25rem;
  position: relative;
  font-size: 0.9rem;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.feature-content li:last-child { border-bottom: none; }

.feature-content li::before {
  content: "✓";
  position: absolute;
  left: 0;
  color: hsl(142, 69%, 45%);
  font-size: 0.8rem;
  font-weight: 700;
}

/* Server rack card */
.server-rack {
  background: rgba(10, 15, 25, 0.9);
  border-radius: 12px;
  padding: 1rem;
  border: 1px solid rgba(255,255,255,0.1);
  min-width: 300px;
  box-shadow: 0 20px 40px rgba(0,0,0,0.4);
}

.server-unit {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1rem;
  background: rgba(255,255,255,0.04);
  border-radius: 8px;
  margin-bottom: 0.75rem;
  border: 1px solid rgba(255,255,255,0.07);
}

.server-unit:last-child { margin-bottom: 0; }

.server-lights { display: flex; gap: 4px; }

.light {
  width: 8px; height: 8px;
  border-radius: 50%;
}
.light.green  { background: #27ca3f; box-shadow: 0 0 4px #27ca3f; }
.light.amber  { background: #f59e0b; box-shadow: 0 0 4px #f59e0b; }

.server-name  { font-size: 0.85rem; font-weight: 600; color: white; margin-bottom: 2px; }
.server-status { font-size: 0.75rem; color: hsl(215,20%,55%); }

/* Control panel card */
.control-panel, .cloudlinux-panel {
  background: rgba(10, 15, 25, 0.9);
  border-radius: 12px;
  padding: 1.25rem;
  border: 1px solid rgba(255,255,255,0.1);
  min-width: 280px;
  box-shadow: 0 20px 40px rgba(0,0,0,0.4);
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid rgba(255,255,255,0.07);
}

.panel-logo { font-size: 1rem; font-weight: 700; color: hsl(217,91%,68%); }
.panel-user { font-size: 0.75rem; color: hsl(215,20%,55%); }

.panel-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
}

.panel-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem;
  background: rgba(255,255,255,0.04);
  border-radius: 8px;
  font-size: 0.8rem;
  color: hsl(215,20%,70%);
  border: 1px solid rgba(255,255,255,0.06);
  text-align: center;
}

.panel-icon { width: 20px; height: 20px; color: hsl(217,91%,60%); }

/* CloudLinux panel */
.cl-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
}

.cl-logo { font-size: 1rem; font-weight: 700; color: hsl(217,91%,68%); }
.cl-status { font-size: 0.75rem; font-weight: 700; color: hsl(142,69%,45%); padding: 2px 8px; background: rgba(34,197,94,0.12); border-radius: 4px; }

.resource-meters { display: flex; flex-direction: column; gap: 0.75rem; }

.resource-meter { display: flex; align-items: center; gap: 0.75rem; }
.meter-label { font-size: 0.8rem; color: hsl(215,20%,60%); width: 55px; flex-shrink: 0; }
.meter-bar { flex: 1; height: 8px; background: rgba(255,255,255,0.08); border-radius: 4px; overflow: hidden; }
.meter-fill { height: 100%; border-radius: 4px; }
.meter-fill.cpu    { background: linear-gradient(to right, hsl(217,91%,55%), hsl(262,83%,60%)); }
.meter-fill.memory { background: linear-gradient(to right, hsl(142,69%,45%), hsl(199,89%,48%)); }
.meter-fill.io     { background: linear-gradient(to right, hsl(38,92%,50%), hsl(30,90%,55%)); }
.meter-value { font-size: 0.8rem; color: hsl(215,20%,65%); width: 35px; text-align: right; flex-shrink: 0; }

@media (max-width: 768px) {
  .hosting-feature { grid-template-columns: 1fr; gap: 2rem; }
  .hosting-feature:nth-child(even) .feature-visual,
  .hosting-feature:nth-child(even) .feature-content { order: unset; }
  .server-rack, .control-panel, .cloudlinux-panel { min-width: unset; width: 100%; }
}
</style>