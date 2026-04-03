<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="isOpen" class="legal-modal-overlay" @click="handleOverlayClick">
        <div class="legal-modal-container" @click.stop>
          <button class="close-button" @click="closeModal" aria-label="Close modal">
            <X :size="24" />
          </button>

          <div class="legal-modal-header">
            <div class="document-icon">
              <FileText :size="32" />
            </div>
            <div class="header-info">
              <h2 class="document-title">{{ documentTitle }}</h2>
              <p v-if="legalDoc?.effective_date" class="effective-date">
                Effective: {{ formatDate(legalDoc.effective_date) }}
                <span v-if="legalDoc?.version" class="version-badge">v{{ legalDoc.version }}</span>
              </p>
            </div>
          </div>

          <div class="legal-modal-content">
            <div v-if="loading" class="loading-state">
              <div class="loading-spinner"></div>
              <p>Loading document...</p>
            </div>
            
            <div v-else-if="error" class="error-state">
              <AlertCircle :size="48" />
              <p>{{ error }}</p>
              <button @click="fetchDocument" class="retry-button">Try Again</button>
            </div>
            
            <div v-else class="document-content" v-html="formattedContent"></div>
          </div>

          <div class="legal-modal-footer">
            <div class="footer-info">
              <p>Last updated: {{ legalDoc?.updated_at ? formatDate(legalDoc.updated_at) : 'N/A' }}</p>
            </div>
            <button @click="closeModal" class="accept-button">
              Close
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { FileText, X, AlertCircle } from 'lucide-vue-next'
import { getLegalDocument, type LegalDocument, type LegalDocumentType } from '@/services/homepageContent'

interface Props {
  modelValue: boolean
  documentType: LegalDocumentType
  customTitle?: string
}

const props = withDefaults(defineProps<Props>(), {
  documentType: 'terms_of_service',
  customTitle: ''
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const legalDoc = ref<LegalDocument | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

// Document title mapping
const documentTitles: Record<LegalDocumentType, string> = {
  terms_of_service: 'Terms of Service',
  privacy_policy: 'Privacy Policy',
  cookie_policy: 'Cookie Policy',
  acceptable_use: 'Acceptable Use Policy',
  sla: 'Service Level Agreement',
  dpa: 'Data Processing Agreement',
  gdpr: 'GDPR Compliance'
}

const documentTitle = computed(() => {
  return props.customTitle || documentTitles[props.documentType] || 'Legal Document'
})

// Convert markdown-like content to HTML
const formattedContent = computed(() => {
  if (!legalDoc.value?.content) return ''
  
  let content = legalDoc.value.content
  
  // Convert ## headers to h3
  content = content.replace(/^## (.+)$/gm, '<h3>$1</h3>')
  
  // Convert # headers to h2
  content = content.replace(/^# (.+)$/gm, '<h2>$1</h2>')
  
  // Convert **bold** to strong
  content = content.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  
  // Convert *italic* to em
  content = content.replace(/\*(.+?)\*/g, '<em>$1</em>')
  
  // Convert numbered lists
  content = content.replace(/^(\d+)\. (.+)$/gm, '<li class="numbered">$2</li>')
  
  // Convert bullet lists
  content = content.replace(/^- (.+)$/gm, '<li class="bullet">$1</li>')
  
  // Wrap consecutive list items in ul
  content = content.replace(/(<li class="(numbered|bullet)">.+<\/li>\n?)+/g, (match) => {
    const type = match.includes('numbered') ? 'ol' : 'ul'
    return `<${type} class="legal-list">${match}</${type}>`
  })
  
  // Convert paragraphs (double newlines)
  content = content.replace(/\n\n/g, '</p><p>')
  
  // Wrap in paragraphs if not already
  if (!content.startsWith('<')) {
    content = '<p>' + content + '</p>'
  }
  
  // Clean up empty paragraphs
  content = content.replace(/<p><\/p>/g, '')
  content = content.replace(/<p>(<h[23]>)/g, '$1')
  content = content.replace(/(<\/h[23]>)<\/p>/g, '$1')
  content = content.replace(/<p>(<[uo]l)/g, '$1')
  content = content.replace(/(<\/[uo]l>)<\/p>/g, '$1')
  
  return content
})

function formatDate(dateStr: string): string {
  try {
    const date = new Date(dateStr)
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  } catch {
    return dateStr
  }
}

async function fetchDocument() {
  loading.value = true
  error.value = null
  
  try {
    const result = await getLegalDocument(props.documentType)
    if (result) {
      legalDoc.value = result
    } else {
      error.value = 'Document not found'
    }
  } catch (e: unknown) {
    console.error('Failed to fetch legal document:', e)
    error.value = 'Failed to load document. Please try again.'
  } finally {
    loading.value = false
  }
}

function closeModal() {
  isOpen.value = false
}

function handleOverlayClick() {
  closeModal()
}

function handleEscKey(e: KeyboardEvent) {
  if (e.key === 'Escape' && isOpen.value) {
    closeModal()
  }
}

// Watch for modal opening to fetch document
watch(() => props.modelValue, (newVal) => {
  if (newVal && !legalDoc.value) {
    fetchDocument()
  }
})

// Also re-fetch if document type changes while open
watch(() => props.documentType, () => {
  if (isOpen.value) {
    legalDoc.value = null
    fetchDocument()
  }
})

onMounted(() => {
  window.addEventListener('keydown', handleEscKey)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleEscKey)
})
</script>

<style scoped>
.legal-modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10000;
  padding: 2rem;
}

.legal-modal-container {
  background: #ffffff;
  border-radius: 16px;
  width: 100%;
  max-width: 800px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
  position: relative;
  animation: modalSlideIn 0.3s ease-out;
}

@keyframes modalSlideIn {
  from {
    opacity: 0;
    transform: translateY(-20px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.close-button {
  position: absolute;
  top: 1rem;
  right: 1rem;
  width: 40px;
  height: 40px;
  border: none;
  background: rgba(0, 0, 0, 0.05);
  border-radius: 10px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6b7280;
  transition: all 0.2s ease;
  z-index: 10;
}

.close-button:hover {
  background: rgba(0, 0, 0, 0.1);
  color: #111827;
}

.legal-modal-header {
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.document-icon {
  width: 56px;
  height: 56px;
  background: linear-gradient(135deg, #635bff 0%, #8b5cf6 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.header-info {
  flex: 1;
}

.document-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 0.25rem 0;
}

.effective-date {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.version-badge {
  background: #f3f4f6;
  color: #374151;
  padding: 0.125rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 600;
}

.legal-modal-content {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
  min-height: 300px;
}

.loading-state,
.error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 200px;
  color: #6b7280;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #e5e7eb;
  border-top-color: #635bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-state {
  color: #ef4444;
}

.error-state p {
  margin: 1rem 0;
}

.retry-button {
  padding: 0.5rem 1rem;
  background: #635bff;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.2s;
}

.retry-button:hover {
  background: #5046e5;
}

.document-content {
  font-size: 0.9375rem;
  line-height: 1.7;
  color: #374151;
}

.document-content :deep(h2) {
  font-size: 1.375rem;
  font-weight: 700;
  color: #111827;
  margin: 2rem 0 1rem 0;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid #635bff;
}

.document-content :deep(h2:first-child) {
  margin-top: 0;
}

.document-content :deep(h3) {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
  margin: 1.5rem 0 0.75rem 0;
}

.document-content :deep(p) {
  margin: 0 0 1rem 0;
}

.document-content :deep(strong) {
  font-weight: 600;
  color: #111827;
}

.document-content :deep(.legal-list) {
  margin: 0.75rem 0;
  padding-left: 1.5rem;
}

.document-content :deep(.legal-list li) {
  margin-bottom: 0.5rem;
}

.document-content :deep(ol.legal-list) {
  list-style-type: decimal;
}

.document-content :deep(ul.legal-list) {
  list-style-type: disc;
}

.legal-modal-footer {
  padding: 1rem 2rem;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f9fafb;
  border-radius: 0 0 16px 16px;
}

.footer-info p {
  font-size: 0.8125rem;
  color: #6b7280;
  margin: 0;
}

.accept-button {
  padding: 0.75rem 2rem;
  background: linear-gradient(135deg, #635bff 0%, #8b5cf6 100%);
  color: white;
  border: none;
  border-radius: 10px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.accept-button:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(99, 91, 255, 0.4);
}

/* Modal transitions */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .legal-modal-container,
.modal-leave-active .legal-modal-container {
  transition: transform 0.3s ease;
}

.modal-enter-from .legal-modal-container {
  transform: translateY(-20px) scale(0.95);
}

.modal-leave-to .legal-modal-container {
  transform: translateY(20px) scale(0.95);
}

/* Scrollbar styling */
.legal-modal-content::-webkit-scrollbar {
  width: 8px;
}

.legal-modal-content::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 4px;
}

.legal-modal-content::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 4px;
}

.legal-modal-content::-webkit-scrollbar-thumb:hover {
  background: #a1a1a1;
}

/* Responsive */
@media (max-width: 768px) {
  .legal-modal-overlay {
    padding: 1rem;
  }
  
  .legal-modal-container {
    max-height: 95vh;
  }
  
  .legal-modal-header {
    padding: 1rem 1.5rem;
    padding-right: 3.5rem;
  }
  
  .document-icon {
    width: 48px;
    height: 48px;
  }
  
  .document-title {
    font-size: 1.25rem;
  }
  
  .legal-modal-content {
    padding: 1.5rem;
  }
  
  .legal-modal-footer {
    padding: 1rem 1.5rem;
    flex-direction: column;
    gap: 1rem;
  }
  
  .accept-button {
    width: 100%;
  }
}
</style>
