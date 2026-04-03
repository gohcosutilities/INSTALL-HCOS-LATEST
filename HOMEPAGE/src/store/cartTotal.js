import {  get } from '@/services/api'
import { defineStore } from 'pinia'; // Import defineStore from Pinia

export const useCartTotalStore = defineStore('cartTotal', {
  state: () => ({
    total: 0, // Initialize with 0 or any default value
  }),
  getters: {
    getTotal:  (state) => {
      state.fetchAndUpdateTotal()
      return state.total

    }
  },
  actions: {
    async fetchAndUpdateTotal() {
      try {
        // Add token to headers if available


        // Fetch the cart total from API
        const response = await get('api/cart-total/');
        const cartTotal = parseFloat(response).toFixed(2);

        // Update the state
        this.setTotal(cartTotal);
        return cartTotal
      } catch (error) {
        console.error('Error fetching cart total:', error);
      }
    },

    setTotal(value) {
      this.total = value;
    },
  },
});
