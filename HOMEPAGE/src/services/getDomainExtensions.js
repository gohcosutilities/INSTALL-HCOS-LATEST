// Ensure the path is correct
import { get } from '@/services/api'
let ext = [];



export const extensionsArray = async () => {
  try {
    let response = await get("frontend-app/available-domain-extension-list/");


    for (let i = 0; i < response.length; i++) {
      ext.push(response[i]);
    }

    return ext;
  } catch (error) {
    console.error('Error fetching extensions:', error);
    throw error;
  }
};
