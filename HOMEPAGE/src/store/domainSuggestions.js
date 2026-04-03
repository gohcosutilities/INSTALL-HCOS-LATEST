import { defineStore } from 'pinia';

export const useDomainSuggestionStore = defineStore('domainSuggestions', {
  state: () => ({
    suggestions: [],
    availability: {},
    searched_domain: '',
    domain_price: '',
    searched_domain_extension: ''
  }),

  getters: {
    getSuggestions: (state) => state.suggestions, 
    getAvailability: (state) => state.availability, 
    getSearchedDomain: (state) => state.searched_domain,
    getDomainPrice: (state) => state.domain_price,
    getSearchedDomainExtension: (state) => state.searched_domain_extension
  },

  actions: {
    updateSuggestions(results) {
      this.suggestions = results; // Action works as expected
     
    },
    updateAvailability(results) {
      this.availability = results; // Action works as expected
    },
    updateSearchedDomain(domain) {
      this.searched_domain = domain; // Action works as expected
    },
    updateDomainPrice(price) {
      this.domain_price = price; // Action works as expected
    },
  },
});