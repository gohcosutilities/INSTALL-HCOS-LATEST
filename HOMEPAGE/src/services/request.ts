import axios from 'axios'
import { getToken, updateToken } from '@/services/auth.ts' // Assuming you have the auth service from previous example

const instance = axios.create({
  baseURL: import.meta.env.VITE_BACKEND_URI,
  withCredentials: true,
})

instance.interceptors.request.use(
  async (config) => {
    await updateToken(() => {});
    const accessToken = getToken();
    
    if (accessToken) {
      localStorage.removeItem('accessToken');
      localStorage.setItem('accessToken', accessToken);
      config.headers['Authorization'] = `Bearer ${accessToken}`;
    }
    
    // Special handling for FormData - don't set Content-Type
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    } else if (!config.headers['Content-Type']) {
      config.headers['Content-Type'] = 'application/json';
    }
      console.log('Request:', config.method, config.url, config.data)
    return config;
  },
  (error) => Promise.reject(error)
);

instance.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // If 401 and we haven't already retried
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      try {
        // Attempt to refresh token
        await updateToken(() => {})
        const newToken = getToken()

        // Retry the original request with new token
        originalRequest.headers['Authorization'] = `Bearer ${newToken}`
        return instance(originalRequest)
      } catch (refreshError) {
        console.error('Failed to refresh token:', refreshError)
        // Redirect to login or handle token refresh failure
        return Promise.reject(refreshError)
      }
    }

    return Promise.reject(error)
  }
)

// Helper function to handle token refresh before requests
const ensureFreshToken = async () => {
  try {
    await updateToken(() => {});
    return true;
  } catch (error) {
    console.error('Token refresh failed:', error);
    return false;
  }
};

export default instance

export const get = async (url: string, params?: Record<string, unknown>) => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required')
  }

  try {
    const response = await instance.get(url, { params })
    return response.data
  } catch (error) {
    console.error('Error fetching data:', error)
    throw error
  }
}

export const post = async <T>(url: string, data?: T, isMultipart = false) => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required');
  }

  try {
    console.log('Posting data:', data);
    const config = isMultipart ? {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    } : {};

    const response = await instance.post(url, data, config);
    return response.data;
  } catch (error) {
    console.error('Error posting data:', error);
    throw error;
  }
};

export const uploadFiles = async (url: string, files: File[], fieldName = 'files') => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required');
  }

  try {
    const formData = new FormData();
    files.forEach(file => {
      formData.append(fieldName, file);
    });

    const response = await instance.post(url, formData);
    return response.data;
  } catch (error) {
    console.error('Error uploading files:', error);
    throw error;
  }
};


export const put = async <T>(url: string, data?: T) => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required')
  }

  try {
    const response = await instance.put(url, data)
    return response.data
  } catch (error) {
    console.error('Error putting data:', error)
    throw error
  }
}

export const del = async (url: string) => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required')
  }

  try {
    const response = await instance.delete(url)
    return response.data
  } catch (error) {
    console.error('Error deleting data:', error)
    throw error
  }
}

export const patch = async <T>(url: string, data?: T) => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required')
  }

  try {
    const response = await instance.patch(url, data)
    return response.data
  } catch (error) {
    console.error('Error patching data:', error)
    throw error
  }
}

export const uploadFile = async (url: string, file: File) => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required')
  }

  const formData = new FormData()
  formData.append('file', file)

  try {
    const response = await instance.post(url, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
    return response.data
  } catch (error) {
    console.error('Error uploading file:', error)
    throw error
  }
}

export const downloadFile = async (url: string) => {
  if (!(await ensureFreshToken())) {
    throw new Error('Authentication required')
  }

  try {
    const response = await instance.get(url, {
      responseType: 'blob',
    })
    const blob = new Blob([response.data], { type: response.headers['content-type'] })
    const link = document.createElement('a')
    link.href = window.URL.createObjectURL(blob)
    link.setAttribute('download', 'file')
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  } catch (error) {
    console.error('Error downloading file:', error)
    throw error
  }
}

const getAuthToken = () => {
  return localStorage.getItem('kc-token');
};


// The request interceptor now uses the local getAuthToken function.
instance.interceptors.request.use(
  (config) => {
    const accessToken = getAuthToken();
    if (accessToken) {
      config.headers['Authorization'] = `Bearer ${accessToken}`;
    }
    
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type'];
    } else if (!config.headers['Content-Type']) {
      config.headers['Content-Type'] = 'application/json';
    }
    
    return config;
  },
  (error) => Promise.reject(error)
);

/**
 * Establishes a WebSocket connection with authentication.
 * Ensures a fresh JWT token is obtained and included in the WebSocket URL.
 *
 * @returns {Promise<WebSocket>} A promise that resolves with the WebSocket instance.
 * @throws {Error} If authentication fails or the base URL is not configured.
 */
export const createWebSocket = async (conversationId) => {
  if (!conversationId) {
    throw new Error('Conversation ID is required for WebSocket connection.');
  }
  
  const accessToken = getAuthToken();
  if (!accessToken) {
    throw new Error('Authentication required for WebSocket connection');
  }

  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
  
  // Construct the correct URL with the conversation ID, as expected by Django's routing.py
  const wsUrl = `${protocol}//request.hcos.io/ws/chat/${conversationId}/?token=${accessToken}`;
  
  console.log(`Attempting to connect to WebSocket: ${wsUrl}`);
  return new WebSocket(wsUrl);
};
