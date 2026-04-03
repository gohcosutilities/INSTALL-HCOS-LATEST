<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getSectionContent } from '@/services/homepageContent'

// Section content with defaults
const sectionTitle = ref('The Journey to HCOS')
const sectionSubtitle = ref('From cardboard-box computers to a global billing powerhouse. Our history is rooted in a deep love for technology and a commitment to solving real-world infrastructure pain.')

// Use branding service
import { useBranding } from '@/services/branding'
const { businessName: brandingName, replaceHCOS } = useBranding()

// Helper to replace HCOS in title while preserving structure
const replaceHCOSInTitle = (title: string) => {
  return title.includes('HCOS') ? title.replace('HCOS', '') : title
}

const timeline = ref([
  {
    year: 'Early Years',
    title: 'The Spark of Curiosity',
    description: 'At age 10, I built my first "computers" out of cardboard boxes and scavenged radio parts, driven by the belief that technology was a new way to reason.'
  },
  {
    year: '2014',
    title: 'Self-Taught Foundations',
    description: 'Deep-dived into the mechanics of the web, mastering FTP, WAMP, and local hosting to launch my first digital projects.'
  },
  {
    year: '2015',
    title: 'Digital Proof of Concept',
    description: 'Achieved my first breakthrough in digital entrepreneurship, successfully generating affiliate commissions through targeted marketing research.'
  },
  {
    year: '2017',
    title: 'A Life-Changing "Mistake"',
    description: 'Coming from a restaurant background, I applied for a "Server" role at a hosting company by mistake. I aced the technical interview and found my true calling.'
  },
  {
    year: '2020',
    title: 'Identifying the Gap',
    description: 'While supporting hosting clients, I saw the industry-wide struggle with expensive, rigid billing tools. I began coding HCOS to solve this for everyone.'
  },
  {
    year: '2025',
    title: 'HCOS: Global Launch',
    description: 'What started as a solo late-night project is now a sophisticated Multi-Tenant Cloud Billing solution serving hosting providers and e-commerce global leaders.'
  },
  {
    year: '2025',
    title: 'A Chance Encounter',
    description: 'An unexpected meeting led to a partnership with a co-CEO who brings over 25 years of experience in business operations to the table. Andrea proposed a tenancy model to meet the needs of modern, progressive businesses.',
    note: 'An idea that came from a now dear partner in life.'
  }
])

const achievements = ref([
  { icon: '🛡️', title: 'Security First', count: '100%', description: 'Built with a fundamental focus on stable, secure architecture.' },
  { icon: '☁️', title: 'Multi-Tenant', count: 'Cloud', description: 'Scaleable infrastructure designed for modern hosting demands.' },
  { icon: '💡', title: 'Experience', count: '15+ Yrs', description: 'Born from a decade of curiosity and hands-on industry support.' },
  { icon: '🚀', title: 'Deployment', count: 'Global', description: 'Empowering providers to automate billing and scale revenue.' }
])

// Always-present hardcoded entry — not overridable via CMS
const chanceEncounterEntry = {
  year: '2025',
  title: 'A Chance Encounter',
  description: 'An unexpected meeting led to a partnership with a co-CEO who brings over 25 years of experience in business operations to the table. Andrea proposed a tenancy model to meet the needs of modern, progressive businesses.',
  note: 'An idea that came from a now dear partner in life.'
}

const bannerTitle = ref('Born from Real Support Experience')
const bannerSubtitle = ref("We didn't build HCOS in a vacuum. We built it while answering thousands of customer tickets, understanding exactly where existing billing solutions fail. We're here to provide the stability and security your business deserves.")
const bannerStats = ref([
  { title: 'Security-First', subtitle: 'Fundamental Core' },
  { title: 'Cloud-Native', subtitle: 'Modern Architecture' },
  { title: 'Founder-Led', subtitle: 'Dedicated to the Vision' }
])

// Load content from backend
onMounted(async () => {
  try {
    const content = await getSectionContent('experience')
    if (content && content.content) {
      const data = content.content
      
      // Update reactive refs with backend data
      if (data.section_title) sectionTitle.value = data.section_title
      if (data.section_subtitle) sectionSubtitle.value = data.section_subtitle
      if (data.timeline && Array.isArray(data.timeline)) timeline.value = [...data.timeline, chanceEncounterEntry]
      if (data.achievements && Array.isArray(data.achievements)) achievements.value = data.achievements
      if (data.banner_title) bannerTitle.value = data.banner_title
      if (data.banner_subtitle) bannerSubtitle.value = data.banner_subtitle
      if (data.banner_stats && Array.isArray(data.banner_stats)) bannerStats.value = data.banner_stats
    }
  } catch (error) {
    console.error('[ExperienceSection] Failed to load content, using defaults:', error)
  }
})
</script>

<template>
  <section id="support" class="experience-section">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="text-center mb-20 animate-on-scroll">
        <h2 class="text-4xl md:text-5xl font-bold text-white mb-6">
          {{ replaceHCOSInTitle(sectionTitle) }}<span v-if="sectionTitle.includes('HCOS')" class="gradient-text">{{ brandingName }}</span>
        </h2>
        <p class="text-xl max-w-3xl mx-auto" style="color: hsl(215,20%,65%)">
          {{ replaceHCOS(sectionSubtitle) }}
        </p>
      </div>

      <div class="mb-20">
          <div class="timeline-surface relative overflow-hidden rounded-[32px] px-4 py-12 sm:px-8 md:px-12">
          <div class="timeline-sheen"></div>
          <div class="relative z-10">
            <div class="timeline-axis absolute left-1/2 top-6 bottom-6 -translate-x-1/2"></div>

            <div class="space-y-14">
              <div 
                v-for="(item, index) in timeline" 
                :key="index"
                :class="[
                  'timeline-item animate-on-scroll relative flex flex-col md:flex-row md:items-center gap-8',
                  index % 2 === 0 ? 'timeline-item-left md:flex-row' : 'timeline-item-right md:flex-row-reverse'
                ]"
              >
                <div 
                  :class="[
                    'timeline-card-wrapper flex-1'
                  ]"
                >
                  <div class="timeline-card">
                    <div class="text-2xl font-bold gradient-text mb-2">{{ item.year }}</div>
                    <h3 class="text-lg font-semibold text-white mb-2">{{ replaceHCOS(item.title) }}</h3>
                    <p class="text-sm leading-relaxed" style="color: hsl(215,20%,65%)">{{ replaceHCOS(item.description) }}</p>
                    <p v-if="item.note" class="text-xs mt-3 italic" style="color: hsl(215,25%,55%)">♥ {{ item.note }}</p>
                  </div>
                </div>

                <div class="timeline-node flex items-center justify-center w-full md:w-auto">
                  <span class="timeline-dot"></span>
                </div>

                <span
                  :class="[
                    'timeline-connector hidden md:block',
                    index % 2 === 0 ? 'timeline-connector-left' : 'timeline-connector-right'
                  ]"
                ></span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
        <div 
          v-for="(achievement, index) in achievements" 
          :key="index"
          class="animate-on-scroll text-center p-8 rounded-2xl hover-lift achievement-card"
        >
          <div class="text-5xl mb-4">{{ achievement.icon }}</div>
          <div class="text-3xl font-bold gradient-text mb-2">{{ achievement.count }}</div>
          <h3 class="text-lg font-semibold text-white mb-2">{{ achievement.title }}</h3>
          <p class="text-sm" style="color: hsl(215,20%,65%)">{{ achievement.description }}</p>
        </div>
      </div>

      <div class="mt-20 animate-on-scroll">
        <div class="hcos-banner experience-background rounded-2xl p-12 text-white text-center">
          <h3 class="text-3xl font-bold mb-6">{{ bannerTitle }}</h3>
          <p class="text-xl mb-8 opacity-90 max-w-3xl mx-auto">
            {{ replaceHCOS(bannerSubtitle) }}
          </p>
          <div class="grid md:grid-cols-3 gap-8 text-center">
            <div v-for="(stat, index) in bannerStats" :key="index">
              <div class="text-2xl font-bold mb-2">{{ stat.title }}</div>
              <div class="text-sm opacity-80">{{ stat.subtitle }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.experience-section {
  padding: 6rem 0;
  background: hsl(222, 47%, 11%);
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.timeline-surface {
  background: rgba(27,35,51,0.5);
  border: 1px solid rgba(255,255,255,0.08);
  box-shadow: 0 20px 60px rgba(0,0,0,0.4);
  backdrop-filter: blur(10px);
}

.achievement-card {
  background: rgba(27,35,51,0.45);
  border: 1px solid rgba(255,255,255,0.08);
  transition: all 0.25s ease;
}

.achievement-card:hover {
  transform: translateY(-4px);
  background: rgba(27,35,51,0.65);
  border-color: rgba(59,130,246,0.3);
}

.hcos-banner {
  background: linear-gradient(135deg, hsl(217,91%,22%) 0%, hsl(262,83%,25%) 100%);
  border: 1px solid rgba(255,255,255,0.1);
}

.experience-background {
  --tw-gradient-from: hsl(217,91%,30%) var(--tw-gradient-from-position);
  --tw-gradient-to: hsl(262,83%,30%) var(--tw-gradient-to-position);
  --tw-gradient-stops: var(--tw-gradient-from), var(--tw-gradient-to);
}
</style>