import { defineStore } from 'pinia'

interface LoadingState { isLoading: boolean }

export const useLoadingStore = defineStore('loading', {
  state: (): LoadingState => ({
    isLoading: false,
  }),
  actions: {
    show() { this.isLoading = true },
    hide() { this.isLoading = false },
  }
})
