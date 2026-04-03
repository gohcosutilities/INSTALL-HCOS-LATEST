import { defineStore } from 'pinia';
import { extensionsArray } from '@/services/getDomainExtensions';

export const useDomainExtensionsStore = defineStore('domainExtensions', {
  state: () => ({
    extensions: [],
    lastFetched: null,
    isLoading: false,
    error: null
  }),

  getters: {
    // Get all extensions in lowercase
    lowercaseExtensions: (state) => state.extensions.map(ext => ext.toLowerCase()),

    // Get extensions sorted by length (descending)
    sortedExtensions: (state) => {
      console.log('Extensions:', state.extensions);
      return [...state.extensions]
        .map(ext => ext.toLowerCase())
        .sort((a, b) => b.length - a.length);
    },

    // Check if data is stale (older than 1 hour)
    isStale: (state) => {
      if (!state.lastFetched) return true;
      const oneHourAgo = new Date(Date.now() - 3600000);
      return new Date(state.lastFetched) < oneHourAgo;
    }
  },

  actions: {
    async fetchExtensions() {
      // Don't fetch if we have recent data and not forced
      if (!this.isStale && this.extensions.length > 0) {
        return;
      }

      this.isLoading = true;
      this.error = null;

      try {
        const data = await extensionsArray();
        this.extensions = data.map(item => item.extension);
        this.lastFetched = new Date().toISOString();
      } catch (err) {
        this.error = err;
        console.error('Failed to fetch domain extensions:', err);
      } finally {
        this.isLoading = false;
      }
    },

    async getDomainExtension(fullDomain) {
      // Ensure we have extensions data
      await this.fetchExtensions();

      const domain = fullDomain.toLowerCase();
      const matchingExtension = this.sortedExtensions.find(ext => domain.endsWith(ext));

      return matchingExtension || null;
    },

    async extractDomainName(fullDomain) {
      const extension = await this.getDomainExtension(fullDomain);
      if (extension) {
        return fullDomain.slice(0, -extension.length);
      }
      return fullDomain;
    }
  }
});
