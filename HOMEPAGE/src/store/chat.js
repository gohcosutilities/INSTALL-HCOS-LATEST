import { ref, computed } from 'vue';
import { defineStore } from 'pinia';
// Assuming your api service is in @/services/api
import { get, post, createWebSocket } from '@/services/api';

// Create separate Audio objects for different notifications.
// Place both 'newChat.mp3' and 'incoming.mp3' in your /public folder.

import newChatSoundFile from '@/assets/audio/newChat.mp3';
import incomingMessageSoundFile from '@/assets/audio/incoming.mp3';

const newChatSound = new Audio(newChatSoundFile);
const incomingMessageSound = new Audio(incomingMessageSoundFile);


export const useChatStore = defineStore('chat', () => {
    // --- STATE ---
    const messages = ref([]);
    const conversations = ref([]);
    const activeConversationId = ref(null);
    const isWidgetOpen = ref(false);
    const isMuted = ref(false);
    const connectionState = ref('CLOSED'); // Values: 'CONNECTING', 'OPEN', 'CLOSED'
    const webSocket = ref(null);

    // --- ACTIONS ---

    /**
     * Toggles the visibility of the client-facing chat widget.
     * Initiates a connection if the widget is opened and not already connected.
     */
    async function toggleWidget() {
        isWidgetOpen.value = !isWidgetOpen.value;
        if (isWidgetOpen.value && !activeConversationId.value) {
            await startOrResumeConversation();
        }
    }

    /**
     * Toggles the sound notification setting.
     */
    function toggleMute() {
        isMuted.value = !isMuted.value;
    }

    /**
     * Closes the existing WebSocket connection if it's open.
     */
    function disconnect() {
        if (webSocket.value) {
            webSocket.value.close();
            webSocket.value = null;
            connectionState.value = 'CLOSED';
            console.log('WebSocket connection closed.');
        }
    }

    /**
     * Connects to the WebSocket for a specific conversation room.
     * @param {string} conversationId - The UUID of the conversation to connect to.
     */
    async function connect(conversationId) {
        if (!conversationId) {
            console.error("Connect action called without a conversationId.");
            return;
        }

        if (webSocket.value && connectionState.value === 'OPEN') {
            disconnect();
        }

        activeConversationId.value = conversationId;
        connectionState.value = 'CONNECTING';

        await fetchMessageHistory(conversationId);

        try {
            webSocket.value = await createWebSocket(conversationId);

            // Connection is already open when Promise resolves
            connectionState.value = 'OPEN';
            console.log(`WebSocket connection established for ${conversationId}.`);

            webSocket.value.onmessage = (event) => {
                const data = JSON.parse(event.data);
                messages.value.push(data);

                // Play the sound for a new incoming message.
                if (!isMuted.value) {
                    incomingMessageSound.play().catch(error => {
                        console.error("Could not play incoming message sound:", error);
                    });
                }
            };

            webSocket.value.onclose = () => {
                connectionState.value = 'CLOSED';
                webSocket.value = null;
                console.log('WebSocket connection closed.');
            };

            webSocket.value.onerror = (error) => {
                console.error('WebSocket error:', error);
                connectionState.value = 'CLOSED';
            };

        } catch (error) {
            console.error('Failed to create WebSocket connection:', error);
            connectionState.value = 'CLOSED';
        }
    }
    
    /**
     * Creates a new conversation or resumes an existing one from localStorage.
     * @param {Object} guestInfo - Optional guest information {guest_name, guest_email}
     */
    async function startOrResumeConversation(guestInfo = null) {
        const existingId = localStorage.getItem('conversationId');
        if (existingId) {
            await connect(existingId);
            return;
        }

        try {
            // Prepare request body with guest info if provided
            const requestBody = guestInfo ? {
                guest_name: guestInfo.guest_name,
                guest_email: guestInfo.guest_email
            } : {};
            
            const newConversation = await post('api/conversations/start/', requestBody);
            const newId = newConversation.id;
            localStorage.setItem('conversationId', newId);
            
            // Store guest info in localStorage for display
            if (guestInfo && guestInfo.guest_name) {
                localStorage.setItem('guestName', guestInfo.guest_name);
                if (guestInfo.guest_email) {
                    localStorage.setItem('guestEmail', guestInfo.guest_email);
                }
            }
            
            // Play the sound for a new chat being created.
            if (!isMuted.value) {
                newChatSound.play().catch(error => {
                    console.error("Could not play new chat sound:", error);
                });
            }

            await connect(newId);
        } catch (error) {
            console.error('Could not start a new conversation:', error);
        }
    }

    /**
     * Sends a message through the active WebSocket connection.
     * @param {string} content - The text content of the message.
     */
    function sendMessage(content) {
        if (webSocket.value && webSocket.value.readyState === WebSocket.OPEN && content) {
            const messagePayload = { message: content };
            webSocket.value.send(JSON.stringify(messagePayload));
        } else {
            console.error('Cannot send message. WebSocket is not open.');
        }
    }

    /**
     * Fetches the list of all conversations for the staff dashboard.
     */
    async function fetchConversations() {
        try {
            const responseData = await get('api/conversations/');
            // When fetching conversations, check if any are new compared to the last check
            // and play the new chat sound. This is a more advanced implementation.
            // For now, sound is only played when the client starts a chat.
            conversations.value = responseData;
        } catch (error) {
            console.error('Error fetching conversations:', error);
        }
    }

    /**
     * Fetches the message history for a specific conversation.
     * @param {string} conversationId - The UUID of the conversation.
     */
    async function fetchMessageHistory(conversationId) {
        try {
            const responseData = await get(`api/conversations/${conversationId}/messages/`);
            messages.value = responseData;
        } catch (error) {
            console.error(`Error fetching message history for ${conversationId}:`, error);
            messages.value = [];
        }
    }

    /**
     * Get CSRF token from cookies
     * Django sets this as 'csrftoken' cookie
     */
    function getCSRFToken() {
        if (typeof document === 'undefined') return null;

        const name = 'csrftoken';
        const cookies = document.cookie.split(';');

        for (let cookie of cookies) {
            cookie = cookie.trim();
            if (cookie.startsWith(name + '=')) {
                return decodeURIComponent(cookie.substring(name.length + 1));
            }
        }
        return null;
    }

    /**
     * Uploads a file attachment to a conversation
     * @param {string} conversationId - The UUID of the conversation
     * @param {File} file - The file to upload
     * @param {string} message - Optional message to accompany the attachment
     * @returns {Promise<Object>} The created message with attachment
     */
    async function uploadAttachment(conversationId, file, message = '') {
        const formData = new FormData();
        formData.append('file', file);
        if (message) {
            formData.append('message', message);
        }

        // Use the API base URL from environment
        const apiBaseUrl = import.meta.env.VITE_BACKEND_URI || '';

        // Get CSRF token for Django
        const csrfToken = getCSRFToken();

        try {
            const headers = {
                // Don't set Content-Type - browser will set it with boundary for FormData
            };

            // Add CSRF token if available
            if (csrfToken) {
                headers['X-CSRFToken'] = csrfToken;
            }

            const response = await fetch(`${apiBaseUrl}/api/conversations/${conversationId}/upload-attachment/`, {
                method: 'POST',
                body: formData,
                credentials: 'include',
                headers
            });

            // Check if response has content before parsing JSON
            const contentType = response.headers.get('content-type');
            let data = null;

            if (contentType && contentType.includes('application/json')) {
                const text = await response.text();
                if (text) {
                    data = JSON.parse(text);
                }
            }

            if (!response.ok) {
                const errorMessage = data?.error || `Upload failed with status ${response.status}`;
                throw new Error(errorMessage);
            }

            // Don't add message locally - WebSocket will broadcast it
            // This prevents duplicate messages

            return { success: true, ...data };
        } catch (error) {
            console.error('Error uploading attachment:', error);
            return { success: false, error: error.message };
        }
    }

    // --- GETTERS ---
    const activeConversation = computed(() => {
        return conversations.value.find(c => c.id === activeConversationId.value);
    });

    return {
        messages,
        conversations,
        activeConversationId,
        isWidgetOpen,
        isMuted,
        connectionState,
        toggleWidget,
        toggleMute,
        connect,
        disconnect,
        sendMessage,
        fetchConversations,
        fetchMessageHistory,
        startOrResumeConversation,
        uploadAttachment,
        activeConversation,
    };
});