import { defineStore } from 'pinia'
import { get } from '@/services/api'
import { getToken }  from '@/services/auth.ts'
import { auth } from '@/services/auth.ts'
export const useUserContextStore = defineStore('userContext', {
  state: () => ({
    user: null as null | {
      id: string | number,
      username: string,
      fullName: string,
      email: string,
      isAuthenticated: boolean,
    },
    permissions: [] as string[],
    userType: null as string | null,
    isLoading: false,
    error: null as any,
    is_staff: false,
    is_superuser: false,
    pollingInterval: null as number | null, // Changed to number for browser environments
    pollingCount: 0,
    products: [] as Array<{status: string}>, // Added products array (comma was missing)
    cart_next_step: null as string | null
  }),

  getters: {
    isAuthenticated: (state) => state.user?.isAuthenticated || false,
    hasPermission: (state) => (perm: string) => state.permissions.includes(perm),
    hasPendingProducts: (state) => state.products.some(product => product.status === 'Pending')
  },

  actions: {
    async fetchProducts() {
      try {
        const response = await get('api/product-list/');
        this.products = response;
      } catch (error) {
        console.error('Failed to fetch products:', error);
        throw error;
      }
    },

    async fetchProductsWithPolling() {
      await this.fetchProducts();
      if (this.hasPendingProducts) {
        this.startPolling();
      }
    },
  
    startPolling() {
      this.stopPolling();
      const interval = this.pollingCount < 10 ? 3000 : 180000;
      this.pollingInterval = window.setInterval(() => { // Using window.setInterval
        this.pollingCount++;
        this.fetchProducts();
        if (this.pollingCount >= 20 || !this.hasPendingProducts) {
          this.stopPolling();
        }
      }, interval);
    },
  
    stopPolling() {
      if (this.pollingInterval) {
        window.clearInterval(this.pollingInterval); // Using window.clearInterval
        this.pollingInterval = null;
      }
      this.pollingCount = 0;
    },

    async fetchUserContext() {
      this.isLoading = true;
      this.error = null;

      try {
        // Get backend context
        const backendData = await get('/api/context');
        console.log("context", backendData);
        
        // Set staff flags
        this.is_staff = !!backendData.is_staff;
        this.is_superuser = !!backendData.is_superuser;

        // Merge with Keycloak data
        const kcData = auth.keycloak.tokenParsed || {};
        this.user = {
          id: backendData.id,
          username: backendData.username,
          fullName: backendData.full_name,
          email: kcData.email || backendData.email,
          isAuthenticated: backendData.is_authenticated,
        };
        this.permissions = backendData.permissions || [];
        this.userType = backendData.user_type || null;

      } catch (err) {
      
        this.error = err;
      } finally {
        this.isLoading = false;
      }
    },
  },
});