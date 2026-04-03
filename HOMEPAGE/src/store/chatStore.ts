import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { Chat, Message, User, ChatStats, OnlineVisitor } from '@/types/chat';
import { chatService } from '@/services/chatService';
import { createWebSocket } from '@/services/api'; // Import createWebSocket

export const useChatStore = defineStore('chat', () => {
  const chats = ref<Chat[]>([]);
  const staff = ref<User[]>([]);
  const stats = ref<ChatStats | null>(null);
  const visitors = ref<OnlineVisitor[]>([]);
  const currentChatId = ref<string | null>(null);
  const isLoading = ref(false);
  const webSocket = ref<WebSocket | null>(null); // WebSocket instance

  // Computed
  const activeChats = computed(() => chats.value.filter(c => c.status === 'active'));
  const waitingChats = computed(() => chats.value.filter(c => c.status === 'waiting'));
  const closedChats = computed(() => chats.value.filter(c => c.status === 'closed'));
  const onlineStaff = computed(() => staff.value.filter(s => s.isOnline));
  const currentChat = computed(() => 
    currentChatId.value ? chats.value.find(c => c.id === currentChatId.value) : null
  );

  // Actions
  async function loadChats() {
    isLoading.value = true;
    try {
      chats.value = await chatService.getChats();
    } finally {
      isLoading.value = false;
    }
  }

  async function loadStaff() {
    staff.value = await chatService.getStaff();
  }

  async function loadStats() {
    stats.value = await chatService.getStats();
  }

  async function loadVisitors() {
    visitors.value = await chatService.getOnlineVisitors();
  }

async function createChat(customerInfo: { name: string; email: string }) {
  const newChat = await chatService.createChat({
    name: customerInfo.name,
    email: customerInfo.email
  });
  chats.value.unshift(newChat);
  await loadStats();
  return newChat;
}

  async function assignChatToStaff(chatId: string, staffId: string) {
    await chatService.assignChatToStaff(chatId, staffId);
    // Optimistically update local state instead of reloading all chats
    const chat = chats.value.find(c => c.id === chatId);
    if (chat) {
      chat.staffId = staffId;
      chat.status = 'active';
      chat.updatedAt = new Date();
    }
    await loadStats();
  }

  async function closeChat(chatId: string) {
    await chatService.closeChat(chatId);
    // Optimistically update local state
    const chat = chats.value.find(c => c.id === chatId);
    if (chat) {
      chat.status = 'closed';
      chat.updatedAt = new Date();
    }
    await loadStats();
  }

  // Modified sendMessage to use WebSocket directly
async function sendMessage(chatId: string, senderId: string, content: string) {
  if (!webSocket.value || webSocket.value.readyState !== WebSocket.OPEN) {
    console.error('WebSocket is not connected. Attempting to reconnect...');
    await connectWebSocket();
    if (!webSocket.value || webSocket.value.readyState !== WebSocket.OPEN) {
      throw new Error('Failed to connect WebSocket');
    }
  }

  const messageData = {
    room_id: chatId,
    message: content,
    sender_id: senderId  // Make sure this matches what your backend expects
  };
  
  webSocket.value.send(JSON.stringify(messageData));
}

  async function markMessagesAsRead(chatId: string) {
    await chatService.markMessagesAsRead(chatId);
    // Update local state
    const chat = chats.value.find(c => c.id === chatId);
    if (chat) {
      chat.messages.forEach(m => m.isRead = true);
    }
  }

  // New action to connect and listen to WebSocket messages
  async function connectWebSocket() {
    if (webSocket.value && webSocket.value.readyState === WebSocket.OPEN) {
      console.log('WebSocket already connected.');
      return;
    }
    try {
      webSocket.value = await createWebSocket();
      webSocket.value.onmessage = (event) => {
          const data = JSON.parse(event.data);
          const incomingMessage: Message = {
              id: data.id,
              chatId: data.room_id,
              senderId: data.sender_id || data.author?.id, // Handle both cases
              content: data.content,
              timestamp: new Date(data.timestamp),
              type: 'text',
              isRead: data.is_read || false,
          };

        // Find the chat and update its messages
        const chat = chats.value.find(c => c.id === incomingMessage.chatId);
        if (chat) {
          chat.messages.push(incomingMessage);
          chat.updatedAt = new Date(); // Update chat's last activity
          // Optionally, move the chat to the top of the list for new messages
          const index = chats.value.indexOf(chat);
          if (index > -1) {
            chats.value.splice(index, 1);
            chats.value.unshift(chat);
          }
        } else {
          console.warn(`Received message for unknown chat ID: ${incomingMessage.chatId}. Consider fetching the chat.`);
          // In a real app, you might trigger a loadChats() or getChatById() here
          // to fetch the new chat if it's a new conversation or a chat not yet loaded.
        }
      };

      webSocket.value.onclose = () => {
        console.log('WebSocket disconnected. Attempting to reconnect...');
        setTimeout(connectWebSocket, 5000); // Reconnect after 5 seconds
      };

      webSocket.value.onerror = (error) => {
        console.error('WebSocket error:', error);
        webSocket.value?.close(); // Close to trigger the onclose handler and reconnect
      };

    } catch (error) {
      console.error('Failed to connect WebSocket:', error);
    }
  }

  function setCurrentChat(chatId: string | null) {
    currentChatId.value = chatId;
  }

  async function initialize() {
    isLoading.value = true;
    try {
      await Promise.all([
        loadChats(),
        loadStaff(),
        loadStats(),
        loadVisitors(),
      ]);
      await connectWebSocket(); // Establish WebSocket connection on initialize
    } catch (error) {
      console.error('Failed to initialize chat store:', error);
    } finally {
      isLoading.value = false;
    }
  }

  async function assignChatToSelf(chatId: string) {
  // Get the current staff member ID (you might need to adjust this based on your auth system)
  const staffId = 2; // Replace with actual staff ID from your auth system
  
  await chatService.assignChatToStaff(chatId, staffId);
  
  // Optimistically update local state
  const chat = chats.value.find(c => c.id === chatId);
  if (chat) {
    chat.staffId = staffId;
    chat.status = 'active';
    chat.updatedAt = new Date();
  }
  await loadStats();
}

  return {
    // State
    chats,
    staff,
    stats,
    visitors,
    currentChatId,
    isLoading, // Expose isLoading state
    webSocket, // Expose WebSocket instance if needed by components directly
    
    // Computed
    activeChats,
    waitingChats,
    closedChats,
    onlineStaff,
    currentChat,
    
    // Actions
    loadChats,
    loadStaff,
    loadStats,
    loadVisitors,
    createChat,
    assignChatToStaff,
    closeChat,
    sendMessage,
    markMessagesAsRead,
    setCurrentChat,
    connectWebSocket, // Expose connectWebSocket if manual connection is desired
    initialize,
    assignChatToSelf, // New action to assign chat to self

  };
});