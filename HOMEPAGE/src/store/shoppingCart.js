// store/shoppingCart.js

import { defineStore } from 'pinia';
import { get, post } from '@/services/api'; // Assuming post is for the delete
import { useUserContextStore } from '@/store/userContext'; 
export const useShoppingCartStore = defineStore('shoppingCart', {
  state: () => ({
    items: [], // Will hold the full line objects from Oscar's basket API
    isLoading : false
  }),
  
  getters: {
    getItems: (state) => state.items,

    hasDomainItems: (state) => {
      return state.items.some(item => Array.isArray(item.domains) && item.domains.length > 0);
    },

    hasHostingProducts: (state) => {
      // TRUE if there is at least one item that is NOT a "domain item"
      return state.items.some(item => !(Array.isArray(item.domains) && item.domains.length > 0));
    },
  },
      hasHostingProducts: (state) => {
      return state.items.some(item => item?.product_class === 'Hosting');
    },

  actions: {

     _updateCartNextStep() { // NEW helper
      const userCtx = useUserContextStore();
      const hasDomain = this.hasDomainItems;
      const hasHosting = this.hasHostingProducts;
      let step = null;

      if (hasDomain && hasHosting) step = '/checkout';
      else if (hasDomain) step = '/add-services';
      else if (hasHosting) step = '/domain-register';

      userCtx.cart_next_step = step;
    },

    /**
     * Fetches the current cart lines from the backend.
     * This should be called anytime the cart is modified by another process.
     */
    async fetchCart() {
      try {
        this.isLoading = true
        // This endpoint should serialize all necessary data for each line,
        // including product_class_name and product_domain.
        this.items = await get('api/cart-lines/');
        this._updateCartNextStep(); // NEW
        console.log('Cart state updated:', this.items);
        console.log('Cart next step:', useUserContextStore().cart_next_step);
      
        this.isLoading = false
      } catch (error) {
        console.error('Failed to fetch cart:', error);
        this.items = []; // Clear items on error
        const userCtx = useUserContextStore();
        userCtx.cart_next_step = null; // reset on error
      } finally {
        this.isLoading = false;
      }
    },

    /**
     * Removes any line from the cart using its unique line ID.
     * This is the NEW, UNIFIED delete action.
     * @param {number} lineId - The primary key of the basket line to remove.
     */
    async removeLineFromCart(lineId) {
      if (!lineId) {
        console.error("removeLineFromCart requires a lineId.");
        return;
      }
      try {
        // This should call an endpoint designed to delete a line by its ID.
        // Oscar's default basket API often uses: DELETE /api/baskets/{basket_id}/lines/{line_id}/
        // We'll use a POST to a custom URL as per your `removeRegularProduct`.
        await post('api/delete-line/', { line_id: lineId });
        
        // After successfully deleting, refresh the cart state from the backend.
        await this.fetchCart();
      } catch (error) {
        console.error(`Failed to remove line ${lineId} from cart:`, error);
      }
    },

    // DEPRECATED: The complex logic from these methods is moved to the new domainStore.
    // REMOVED: async addToCart(...)
    // REMOVED: async removeFromCart(...)
    // REMOVED: async removeRegularProduct(...)
  },
});