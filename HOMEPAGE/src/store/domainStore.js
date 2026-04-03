// store/domainStore.js (you can rename domainStore.js to this)

import { defineStore } from "pinia";
import { post } from '@/services/api'; // Use a generic API service
import { useShoppingCartStore } from '@/store/shoppingCart';

export const useDomainStore = defineStore("domain", {
  state: () => ({
    // State for the UI
    searchedDomain: '',
    availability: null,
    suggestions: [],
    isLoading: false,
    error: null,
    billingTerm: "0",
  }),

  actions: {
    /**
     * Handles the initial search for domain availability and suggestions.
     * This is the answer to your second question.
     */
    async searchDomainAvailability(payload) {
      this.isLoading = true;
      this.error = null;
      try {
        // This action should call your BasketAnalyzer to get suggestions
        // and availability without adding anything to the cart.
        const response = await post('api/domain-check/', {
            intention: 'Search',
            domain_name: payload.domain_name,
            billingTerm: payload.billingTerm,

        },
        { x: 1 },
        { requireAuth: true, autoLogin: true }
      
      
      );
        this.availability = response.is_available;
        this.suggestions = response.domain_suggestions.SuggestionsList;
        this.searchedDomain = response.searched_domain;
        this.billingTerm = response.billing_term;
      } catch (e) {
        this.error = 'Failed to search for domain.';
        console.error(e);
      } finally {
        this.isLoading = false;
      }
    },

    /**
     * Adds a NEW or TRANSFER domain product to the cart AND associates it with the hosting service.
     */
    async addDomainToCartAndAssociate(payload) {
      // { domain_name: 'example.com', intention: 'NewDomain', billingTerm: 'Annually' }
      this.isLoading = true;
      this.error = null;
      try {
        const response = await post('api/domain-check/', payload);
        const validResponses = ['DOMAIN_ADDED_AND_LINKED','DOMAIN_ADDED']
        if (validResponses.includes(response.status)) {
          // Success! Tell the shopping cart to refresh its state.
          const cartStore = useShoppingCartStore();
          await cartStore.fetchCart();
          return response; // Return response for further handling
        } else {
          throw new Error(response.error || 'Failed to add domain.');
        }
      } catch (e) {
        this.error = e.message;
        console.error(e);
        throw e; // Re-throw for proper error handling in components
      } finally {
        this.isLoading = false;
      }
    },

    /**
     * Associates an EXISTING domain with the hosting service.
     * Does NOT add a product to the cart.
     */
    async associateExistingDomain(payload) {
      // { domain_name: 'example.com', intention: 'ExistingDomain' }
      this.isLoading = true;
      this.error = null;
      try {
        const response = await post('api/domain-check/', payload);
        if (response.status === 'EXISTING_DOMAIN_LINKED') {
          // Success! The cart was modified (a line was updated), so refresh it.
          const cartStore = useShoppingCartStore();
          await cartStore.fetchCart();
        } else {
          throw new Error(response.error || 'Failed to associate domain.');
        }
      } catch (e) {
        this.error = e.message;
        console.error(e);
      } finally {
        this.isLoading = false;
      }
    },
  },
});