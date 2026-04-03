import {  get } from '@/services/api'
import { defineStore } from 'pinia'

export const useAddressStore = defineStore('address', {
  state: () => ({
    address: {
      firstName: null,
      lastName: null,
      email: null,
      phone: null,
      password: null,

      country: null,
      countryCode: null,

      state: null,
      zip: null,
      line1: null,
      line2: null,
      line3: null,
      line4: null,
    },
  }),
  getters: {
    getAddressOnly: (state) => {
      return state.address
    },

    getAddress: (state) => {
      state.fetchAndUpdateAddress()
      return state.address
    },
  },
  actions: {
    async fetchAndUpdateAddress() {
      try {
        // Fetch the address from API
        const response = await get('api/user-credentials/')
        const address = response

        // Update the state
        this.setAddress(address)
        return address
      } catch (error) {
        console.error('Error fetching address:', error)
      }
    },

    setAddress(address) {
      this.address = address
    },
  },
})
