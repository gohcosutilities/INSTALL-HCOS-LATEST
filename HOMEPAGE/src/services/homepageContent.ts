/**
 * Homepage Content Service
 * Fetches editable content from the backend for homepage sections.
 */
import axios from 'axios'

const baseURL = import.meta.env.VITE_BACKEND_URI || 'http://localhost:8000'

// Simple axios instance without auth for public content
const publicApi = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Cache for section content
const contentCache: Record<string, { data: any; timestamp: number }> = {}
const CACHE_DURATION = 5 * 60 * 1000 // 5 minutes

/**
 * Get all homepage sections content
 */
export async function getAllSections(): Promise<Record<string, any>> {
  const cacheKey = 'all_sections'
  const cached = contentCache[cacheKey]
  
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data
  }
  
  try {
    const response = await publicApi.get('/api/accounts/homepage/public/')
    const data = response.data
    
    contentCache[cacheKey] = { data, timestamp: Date.now() }
    return data
  } catch (error) {
    console.error('Failed to fetch homepage sections:', error)
    return { sections: {} }
  }
}

/**
 * Get a specific section's content by type
 */
export async function getSectionContent(sectionType: string): Promise<any> {
  const cacheKey = `section_${sectionType}`
  const cached = contentCache[cacheKey]
  
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data
  }
  
  try {
    const response = await publicApi.get(`/api/accounts/homepage/public/${sectionType}/`)
    const data = response.data
    
    contentCache[cacheKey] = { data, timestamp: Date.now() }
    return data
  } catch (error) {
    console.error(`Failed to fetch ${sectionType} section:`, error)
    return null
  }
}

/**
 * Clear the content cache (useful when testing)
 */
export function clearCache() {
  Object.keys(contentCache).forEach(key => delete contentCache[key])
}

/**
 * Pre-fetch all sections (can be called on app mount)
 */
export async function prefetchAllSections() {
  try {
    await getAllSections()
    console.log('[Homepage] Content prefetched successfully')
  } catch (error) {
    console.error('[Homepage] Failed to prefetch content:', error)
  }
}

// =====================================================
// Legal Document Types and Functions
// =====================================================

export type LegalDocumentType = 
  | 'terms_of_service'
  | 'privacy_policy' 
  | 'cookie_policy'
  | 'acceptable_use'
  | 'sla'
  | 'dpa'
  | 'gdpr'

export interface LegalDocument {
  id: number
  document_type: LegalDocumentType
  title: string
  content: string
  summary: string
  version: string
  effective_date: string
  is_active: boolean
  created_at: string
  updated_at: string
}

// Cache for legal documents
const legalDocumentCache: Record<string, { data: LegalDocument; timestamp: number }> = {}
const LEGAL_CACHE_DURATION = 10 * 60 * 1000 // 10 minutes

/**
 * Get a legal document by type (public endpoint)
 */
export async function getLegalDocument(documentType: LegalDocumentType): Promise<LegalDocument | null> {
  const cacheKey = `legal_${documentType}`
  const cached = legalDocumentCache[cacheKey]
  
  if (cached && Date.now() - cached.timestamp < LEGAL_CACHE_DURATION) {
    return cached.data
  }
  
  try {
    const response = await publicApi.get(`/api/accounts/legal/public/${documentType}/`)
    const data = response.data
    
    legalDocumentCache[cacheKey] = { data, timestamp: Date.now() }
    return data
  } catch (error) {
    console.error(`Failed to fetch legal document (${documentType}):`, error)
    return null
  }
}

/**
 * Clear legal document cache
 */
export function clearLegalDocumentCache() {
  Object.keys(legalDocumentCache).forEach(key => delete legalDocumentCache[key])
}

/**
 * Pre-fetch common legal documents
 */
export async function prefetchLegalDocuments() {
  const commonDocs: LegalDocumentType[] = ['terms_of_service', 'privacy_policy', 'cookie_policy']
  
  try {
    await Promise.all(commonDocs.map(docType => getLegalDocument(docType)))
    console.log('[Legal] Documents prefetched successfully')
  } catch (error) {
    console.error('[Legal] Failed to prefetch documents:', error)
  }
}
