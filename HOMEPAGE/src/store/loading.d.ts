export interface LoadingStoreState { isLoading: boolean }
export interface LoadingStoreActions { show(): void; hide(): void }
export const useLoadingStore: () => LoadingStoreState & LoadingStoreActions
