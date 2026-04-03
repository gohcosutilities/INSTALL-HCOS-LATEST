<template>
  <section id="hero" class="hero">
    <canvas ref="canvas" class="hero-canvas"></canvas>
    <div class="hero-overlay"></div>
    <!-- Gradient blobs like React version -->
    <div class="hero-blob hero-blob-right"></div>
    <div class="hero-blob hero-blob-left"></div>
    <div class="container">
      <div class="hero-content">
        <div class="hero-text" data-aos="fade-up">
          <div class="hero-badge">v2.0 Beta &bull; Now Available</div>
          <h1 class="hero-title">
            Hosting &amp; Commerce<br />
            <span class="gradient-text">Operating System</span>
          </h1>
          <p class="hero-subtitle">
            Launch hosting products, automate billing, and run e-commerce in one managed platform. Vendors connect their own payment processors and servers while {{ brandingName }} handles onboarding, checkout, and day-to-day automation.
          </p>
          <div class="hero-actions">
            <button class="btn btn-primary-hero" @click="props.onOpenContactSales?.()">Start Setup</button>
            <button class="btn btn-ghost-hero" @click="props.onOpenDemo?.()">
              Explore the platform
              <svg class="arrow-icon" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 8h10M9 4l4 4-4 4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </button>
          </div>
          <div class="hero-stats">
            <div class="stat">
              <h3>100%</h3>
              <p>Vendor-owned payments</p>
            </div>
            <div class="stat">
              <h3>Multi-tenant</h3>
              <p>Isolated control per vendor</p>
            </div>
            <div class="stat">
              <h3>Hourly → Annual</h3>
              <p>Billing models covered</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { useBranding } from '@/services/branding'

const { businessName: brandingName } = useBranding()

const props = defineProps<{
  onOpenContactSales?: () => void
  onOpenDemo?: () => void
}>()

const canvas = ref<HTMLCanvasElement>()
let cleanupCanvas: (() => void) | null = null

onMounted(() => {
  if (canvas.value) {
    const ctx = canvas.value.getContext('2d')
    if (ctx) {
      cleanupCanvas = initCanvas(ctx)
    }
  }
})

onUnmounted(() => {
  cleanupCanvas?.()
})

const initCanvas = (ctx: CanvasRenderingContext2D) => {
  const resizeCanvas = () => {
    if (canvas.value) {
      canvas.value.width = window.innerWidth
      canvas.value.height = window.innerHeight
    }
  }
  
  resizeCanvas()
  window.addEventListener('resize', resizeCanvas)
  
  const particles: Array<{
    x: number
    y: number
    vx: number
    vy: number
    size: number
    opacity: number
    color: string
  }> = []
  
  const lightRays: Array<{
    x: number
    y: number
    angle: number
    length: number
    width: number
    opacity: number
    speed: number
    maxOpacity: number
  }> = []
  
  // Create floating blue particles
  for (let i = 0; i < 80; i++) {
    particles.push({
      x: Math.random() * canvas.value!.width,
      y: Math.random() * canvas.value!.height,
      vx: (Math.random() - 0.5) * 0.3,
      vy: (Math.random() - 0.5) * 0.3,
      size: Math.random() * 2 + 0.5,
      opacity: Math.random() * 0.4 + 0.1,
      color: Math.random() > 0.7 ? '#58a6ff' : '#1f6feb'
    })
  }
  
  // Create light rays emanating from background
  for (let i = 0; i < 8; i++) {
    lightRays.push({
      x: Math.random() * canvas.value!.width,
      y: Math.random() * canvas.value!.height,
      angle: Math.random() * Math.PI * 2,
      length: 400 + Math.random() * 600,
      width: 2 + Math.random() * 4,
      opacity: 0,
      speed: 0.005 + Math.random() * 0.01,
      maxOpacity: 0.15 + Math.random() * 0.1
    })
  }
  
  let time = 0
  
  const animate = () => {
    time += 0.016 // ~60fps
    ctx.clearRect(0, 0, canvas.value!.width, canvas.value!.height)
    
    // Draw light rays
    lightRays.forEach((ray, index) => {
      // Animate opacity with sine wave for smooth breathing effect
      ray.opacity = (Math.sin(time * ray.speed + index) + 1) * 0.5 * ray.maxOpacity
      
      if (ray.opacity > 0.01) {
        const startX = ray.x
        const startY = ray.y
        const endX = startX + Math.cos(ray.angle) * ray.length
        const endY = startY + Math.sin(ray.angle) * ray.length
        
        // Create gradient for light ray
        const gradient = ctx.createLinearGradient(startX, startY, endX, endY)
        gradient.addColorStop(0, `rgba(88, 166, 255, ${ray.opacity})`)
        gradient.addColorStop(0.5, `rgba(31, 111, 235, ${ray.opacity * 0.6})`)
        gradient.addColorStop(1, `rgba(88, 166, 255, 0)`)
        
        // Draw main light ray
        ctx.strokeStyle = gradient
        ctx.lineWidth = ray.width
        ctx.lineCap = 'round'
        ctx.beginPath()
        ctx.moveTo(startX, startY)
        ctx.lineTo(endX, endY)
        ctx.stroke()
        
        // Draw softer outer glow
        const glowGradient = ctx.createLinearGradient(startX, startY, endX, endY)
        glowGradient.addColorStop(0, `rgba(88, 166, 255, ${ray.opacity * 0.3})`)
        glowGradient.addColorStop(0.5, `rgba(31, 111, 235, ${ray.opacity * 0.2})`)
        glowGradient.addColorStop(1, `rgba(88, 166, 255, 0)`)
        
        ctx.strokeStyle = glowGradient
        ctx.lineWidth = ray.width * 3
        ctx.stroke()
      }
      
      // Slowly drift the light rays
      ray.x += Math.cos(ray.angle * 0.1) * 0.2
      ray.y += Math.sin(ray.angle * 0.1) * 0.2
      ray.angle += 0.001
      
      // Wrap around screen edges
      if (ray.x < -200) ray.x = canvas.value!.width + 200
      if (ray.x > canvas.value!.width + 200) ray.x = -200
      if (ray.y < -200) ray.y = canvas.value!.height + 200
      if (ray.y > canvas.value!.height + 200) ray.y = -200
    })
    
    // Draw floating blue particles
    particles.forEach((particle) => {
      particle.x += particle.vx
      particle.y += particle.vy
      
      if (particle.x < 0 || particle.x > canvas.value!.width) particle.vx *= -1
      if (particle.y < 0 || particle.y > canvas.value!.height) particle.vy *= -1
      
      ctx.beginPath()
      ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(${particle.color === '#58a6ff' ? '88, 166, 255' : '31, 111, 235'}, ${particle.opacity})`
      ctx.fill()
      
      // Add subtle glow to particles
      ctx.shadowColor = particle.color
      ctx.shadowBlur = 8
      ctx.fill()
      ctx.shadowBlur = 0
    })
    
    requestAnimationFrame(animate)
  }
  
  animate()
  return () => {
    window.removeEventListener('resize', resizeCanvas)
  }
}
</script>

<style scoped>
.hero {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  overflow: hidden;
  background: hsl(222, 47%, 11%);
}

.hero-canvas {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
}

/* Gradient blobs matching React version */
.hero-blob {
  position: absolute;
  border-radius: 50%;
  filter: blur(100px);
  pointer-events: none;
  z-index: 1;
  opacity: 0.45;
}
.hero-blob-right {
  top: 0;
  right: 0;
  width: 500px;
  height: 500px;
  background: hsl(217, 91%, 60%);
  mix-blend-mode: screen;
}
.hero-blob-left {
  bottom: 0;
  left: 0;
  width: 350px;
  height: 350px;
  background: hsl(262, 83%, 58%);
  mix-blend-mode: screen;
}

.hero-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    45deg,
    rgba(13, 17, 23, 0.75) 0%,
    rgba(5, 12, 22, 0.55) 40%,
    rgba(37, 99, 235, 0.04) 70%,
    rgba(88, 166, 255, 0.02) 100%
  );
  z-index: 2;
}

.hero-overlay::before {
  content: '';
  position: absolute;
  top: -50%;
  left: -50%;
  width: 200%;
  height: 200%;
  background: 
    linear-gradient(45deg, transparent 40%, rgba(88, 166, 255, 0.08) 50%, transparent 60%),
    linear-gradient(-45deg, transparent 40%, rgba(37, 99, 235, 0.06) 50%, transparent 60%);
  animation: lightSweep 15s ease-in-out infinite;
  pointer-events: none;
}

@keyframes lightSweep {
  0%, 100% { transform: translateX(-20%) translateY(-20%) rotate(0deg); opacity: 0.3; }
  25%       { transform: translateX(0%)   translateY(-10%) rotate(5deg);  opacity: 0.55; }
  50%       { transform: translateX(10%)  translateY(0%)   rotate(-3deg); opacity: 0.35; }
  75%       { transform: translateX(-5%)  translateY(10%)  rotate(2deg);  opacity: 0.65; }
}

.hero-content {
  position: relative;
  z-index: 3;
  padding: 6rem 0 4rem;
  width: 100%;
  display: flex;
  justify-content: center;
}

.hero-text {
  max-width: 720px;
  margin: 0 auto;
  text-align: center;
}

/* Badge pill - matches React's <Badge> component */
.hero-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border-radius: 9999px;
  background: rgba(59, 130, 246, 0.12);
  color: hsl(217, 91%, 72%);
  border: 1px solid rgba(59, 130, 246, 0.25);
  font-weight: 600;
  font-size: 0.75rem;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  margin-bottom: 1.25rem;
}

.hero-title {
  font-family: var(--font-display);
  font-size: clamp(2.75rem, 6vw, 4.5rem);
  font-weight: 800;
  color: white;
  line-height: 1.1;
  letter-spacing: -0.03em;
  margin: 0 0 1.5rem 0;
}

/* Override global gradient-text for this component */
.hero-text .gradient-text {
  font-family: inherit;
  font-size: inherit;
  font-weight: inherit;
  letter-spacing: inherit;
  line-height: inherit;
  display: inline;
  background: linear-gradient(to right, hsl(214, 91%, 65%), hsl(235, 90%, 68%), hsl(262, 83%, 65%));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  filter: none;
}

.hero-subtitle {
  font-size: 1.125rem;
  color: hsl(215, 20%, 70%);
  margin-bottom: 2.5rem;
  line-height: 1.7;
  max-width: 600px;
  margin-left: auto;
  margin-right: auto;
}

.hero-actions {
  display: flex;
  gap: 1rem;
  margin-bottom: 3rem;
  flex-wrap: wrap;
  justify-content: center;
}

/* Primary CTA — white button like React "Start Building Free" */
.btn-primary-hero {
  padding: 14px 28px;
  background: white;
  color: #0d1117;
  border: none;
  border-radius: 8px;
  font-weight: 700;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.15s ease;
  box-shadow: 0 4px 14px rgba(255, 255, 255, 0.15);
}

.btn-primary-hero:hover {
  background: #f0f4f8;
  transform: scale(1.02);
  box-shadow: 0 6px 20px rgba(255, 255, 255, 0.2);
}

/* Ghost/secondary CTA */
.btn-ghost-hero {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 14px 24px;
  background: transparent;
  color: rgba(255, 255, 255, 0.85);
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.15s ease;
}

.btn-ghost-hero:hover {
  background: rgba(255, 255, 255, 0.06);
  color: white;
}

.arrow-icon {
  width: 16px;
  height: 16px;
}

.hero-stats {
  display: flex;
  gap: 3rem;
  padding-top: 2rem;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  justify-content: center;
  flex-wrap: wrap;
}

.stat h3 {
  font-family: var(--font-display);
  font-size: 1.75rem;
  font-weight: 800;
  color: hsl(217, 91%, 68%);
  margin: 0 0 0.35rem 0;
  letter-spacing: -0.02em;
}

.stat p {
  color: hsl(215, 20%, 65%);
  font-size: 0.875rem;
  margin: 0;
}

@media (max-width: 768px) {
  .hero-title { font-size: 2.5rem; }
  .hero-subtitle { font-size: 1rem; }
  .hero-actions { flex-direction: column; align-items: center; }
  .hero-stats { gap: 2rem; }
  .hero-blob-right { width: 280px; height: 280px; }
  .hero-blob-left  { width: 200px; height: 200px; }
}
</style>
