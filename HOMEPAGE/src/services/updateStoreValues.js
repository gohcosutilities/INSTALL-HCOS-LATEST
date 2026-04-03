import { useDomainStore } from "@/store/domainStore";
const updateStoreValues = (action, domainDetails = {}) => {
    const domainQueryStore = useDomainStore();
    const currentValues = { ...domainQueryStore.getRegistrationValues }; // Get current store values
  
    // Define the new values based on the action
    let newValues;
  
    switch (action) {
      case "search":
        newValues = {
          ...currentValues,
          searchedDomain: domainDetails.searchedDomain || "",
          domainExtension: domainDetails.domainExtension || "",
          billingterm: domainDetails.billingterm || "Annually",
          intention: domainDetails.intention || "NewDomain",
          deleteDomain: false, // Reset deleteDomain
          addToCart: {
            new: false,
            transfer: false,
            existing: false,
          },
          nextStep: null, // Reset nextStep
          eppCode: domainDetails.eppCode // Reset EPP code
        };
        break;
  
      case "addToCart":
        newValues = {
          ...currentValues,
          deleteDomain: false, // Reset deleteDomain
          addToCart: {
            new: domainDetails.intention === "NewDomain",
            transfer: domainDetails.intention === "TransferDomain",
            existing: domainDetails.intention === "ExistingDomain",
            
          },
          searchedDomain: domainDetails.searchedDomain || "",
          domainExtension: domainDetails.domainExtension || "",
          billingterm: domainDetails.billingterm || "Annually",
          intention: domainDetails.intention || "NewDomain",
          nextStep: "Checkout", // Set nextStep to cart
        };
        break;
  
      case "deleteDomain":
        newValues = {
          ...currentValues,
          deleteDomain: true, // Set deleteDomain to true
          addToCart: {
            new: false,
            transfer: false,
            existing: false,
          },
          nextStep: null, // Reset nextStep
        };
        break;
  
      default:
        newValues = currentValues; // No changes if action is invalid
    }
  
    // Check if the new values are different from the current values
    const hasChanged = JSON.stringify(newValues) !== JSON.stringify(currentValues);
  
    // Update the store if values have changed
    if (hasChanged) {
      domainQueryStore.updateRegistrationValues(newValues);
    }
  
    return hasChanged; // Return whether the values were updated
  };

export default updateStoreValues