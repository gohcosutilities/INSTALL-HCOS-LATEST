import { post } from '@/services/api';

/**
 * REFACTORED: Makes a request to the backend domain handler endpoint.
 *
 * This is now a simple, stateless async function instead of a class. It has no
 * knowledge of global state. The calling Pinia store (e.g., `domainStore`) is
 * responsible for managing its own loading and error states.
 *
 * @param {Object} payload - The data object to be sent to the backend. This payload
 * is constructed directly in the Pinia store action that calls this function.
 * @returns {Promise<Object>} The JSON response data from the API.
 * @throws {Error} Throws an error if the API call fails, which can be caught by the calling action.
 */
export const searchDomainAPI = async (payload) => {
  try {
    // The function now simply takes the payload and passes it to the post utility.
    // The endpoint URL has been updated to match your backend refactor.
    const response = await post('api/domain-check/', payload);
    return response;
  } catch (error) {
    // Log the error for debugging purposes.
    console.error('Error in searchDomainAPI service:', error);
    
    // Re-throw the error. This is crucial because it allows the calling
    // Pinia store action to catch the error and update its state accordingly
    // (e.g., set an error message for the user).
    throw error;
  }
};