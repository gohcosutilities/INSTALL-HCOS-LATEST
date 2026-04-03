import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Invoice } from '../types' // Assuming your Invoice type is correctly defined
import { get,post } from '@/services/api';// Import get helper

// It's good practice to configure a base URL for get if all your API calls go to the same domain
// This can be done in a central place, e.g., main.ts or an get configuration file.
// For example:
// get.defaults.baseURL = 'http://localhost:8000/api/'; // Or your actual API base URL
// Ensure get is configured to send authentication tokens if your API requires it.



export const useInvoiceStore = defineStore('invoices', () => {
  const invoices = ref<Invoice[]>([]);
  const isLoading = ref<boolean>(false);
  const paymentProcessing = ref<boolean>(false); // For payment button loading state
  const error = ref<string | null>(null);

 const generatePayPalOrder = async (invoiceId: number | string) => {
    paymentProcessing.value = true;
    error.value = null;
    try {
      // This is a NEW API endpoint you'll need to create in Django
      const response = await post<{ order_id: string; approval_url: string }>(
        `api/billing/invoices/${invoiceId}/create-paypal-order/`
        // If your API is namespaced differently, adjust the URL.
        // This endpoint should call the invoice.create_paypal_order() method on your Django model.
      );
      
      if (response && response.approval_url) {
        // Update the specific invoice in the store if needed, though direct redirect is common
        const invoiceIndex = invoices.value.findIndex(inv => inv.number === invoiceId || inv.number === invoiceId);
        if (invoiceIndex !== -1) {
          invoices.value[invoiceIndex].paypal_approval_link = response.approval_url;
          // invoices.value[invoiceIndex].paypal_order_id = response.order_id; // If you store this too
        }
        // Redirect the user to PayPal
        window.location.href = response.approval_url;
        return true; // Indicate success for UI if needed before redirect
      } else {
        console.log("The Response from order endpoint",  response.approval_url)
        throw new Error('PayPal approval URL not found in response.');
      }
    } catch (e: any) {
      console.error(`Failed to generate PayPal order for invoice ${invoiceId}:`, e);
      const errorMessage = e.response?.data?.detail || e.response?.data?.error || e.message || 'Could not initiate PayPal payment.';
      error.value = errorMessage;
      // alert(errorMessage); // Or handle error display in component
      return false; // Indicate failure
    } finally {
      paymentProcessing.value = false;
    }
  };

  const clearError = () => {
    error.value = null;
  }
  const setError = (errorMessage: string) => {
    error.value = errorMessage;
  }


  /**
   * Fetches all invoices from the backend API.
   */
   const fetchInvoices = async () => {
    isLoading.value = true;
    error.value = null;
    try {
      const response = await get<Invoice[]>('api/billing/invoices/');
      
      // --- START DEBUG LOGS ---
      console.log('API Response Status:', response.status);

      console.log('Type of response:', typeof response);
      console.log('Is response an array?:', Array.isArray(response));
      console.log('Actual API response:', response);
      // --- END DEBUG LOGS ---

      // Defensive assignment: only assign if it's an array
      if (Array.isArray(response)) {
        invoices.value = response;
      } else {
        console.error('Error: API did not return an array for invoices!', 'Received:', response);
        invoices.value = []; // Fallback to an empty array to prevent iteration errors elsewhere
        // Optionally set a more specific error message for the UI
        error.value = 'Failed to load invoices: Unexpected data format from server.';
      }
    } catch (e: any) {
      console.error('Failed to fetch invoices (exception):', e);
      invoices.value = []; // Ensure invoices is an array on error
      if (get.isgetError(e)) {
        error.value = e.response?.data?.detail || e.message || 'An unknown error occurred while fetching invoices.';
      } else if (e instanceof Error) {
        error.value = e.message;
      } else {
        error.value = 'An unexpected error occurred.';
      }
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Fetches a single invoice by its ID from the API.
   * Assumes your API supports an endpoint like 'api/billing/invoices/<id>/'
   * If not, you might rely on `getInvoiceByIdFromLocal` after calling `fetchInvoices`.
   * @param id The ID (number) of the invoice to fetch.
   */
  const fetchInvoiceById = async (id: number | string) => {
    isLoading.value = true;
    error.value = null;
    try {
      // Adjust the endpoint to match your API for fetching a single invoice
      const response = await get<Invoice>(`api/billing/invoices/${id}/`);
      // Update the local list or add/replace the fetched invoice
      const index = invoices.value.findIndex(inv => inv.number === response.number); // Or inv.id if you have a unique PK
      if (index !== -1) {
        invoices.value[index] = response;
      } else {
        invoices.value.push(response); // Add if not already in the list (less likely if navigating from a list)
      }
      console.log('Fetched Invoice:', response);
      return response; // Return the fetched invoice
    } catch (e: any) {
      console.error(`Failed to fetch invoice with ID ${id}:`, e);
      if (get.isgetError(e)) {
        error.value = e.response?.data?.detail || e.message || `Error fetching invoice ${id}.`;
      } else if (e instanceof Error) {
        error.value = e.message;
      } else {
        error.value = 'An unexpected error occurred.';
      }
      return undefined; // Return undefined on error
    } finally {
      isLoading.value = false;
    }
  }


  // Get an invoice by ID (number) from the locally stored invoices
  // This is useful if `fetchInvoices` has already been called.
  const getInvoiceByIdFromLocal = (id: number): Invoice | undefined => {
    // Ensure 'id' is treated as a number if invoice.number is numeric.
    // The 'number' field in your sample data (e.g., 1748576162668) is quite large.
    // Make sure the 'id' parameter type and comparison match your actual identifier.
    return invoices.value.find(invoice => invoice.number === id)
  }

  // Filter invoices by status
  const filterInvoicesByStatus = (status: string | null) => {
    if (!status) return invoices.value
    return invoices.value.filter(invoice => invoice.status === status)
  }

  // Sort invoices by issue date (descending)
  const sortedInvoices = computed(() => {
    return [...invoices.value].sort((a, b) => {
      // Ensure issue_date is valid before creating Date objects
      const dateA = a.issue_date ? new Date(a.issue_date).getTime() : 0;
      const dateB = b.issue_date ? new Date(b.issue_date).getTime() : 0;
      return dateB - dateA; // Descending order
    })
  })

  return {
    invoices, // The reactive list of invoices
    isLoading,
    error,
    fetchInvoices, // Action to fetch all invoices
    fetchInvoiceById, // Action to fetch a single invoice by ID
    getInvoiceById: getInvoiceByIdFromLocal, // Getter for local data (renamed for clarity or keep as is)
    filterInvoicesByStatus,
    generatePayPalOrder,
    paymentProcessing,
    sortedInvoices,
    clearError,
    setError
  }
})