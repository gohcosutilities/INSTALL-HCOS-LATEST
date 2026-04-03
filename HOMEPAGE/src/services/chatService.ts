import type { Chat, Message, User, ChatStats, OnlineVisitor } from '@/types/chat';
import { get, post } from '@/services/api'; // Import get and post from the new api.ts

class ChatService {
  // Chat operations
  async getChats(): Promise<Chat[]> {
    return get('chats/');
  }

  async getChatById(id: string): Promise<Chat | null> {
    return get(`chats/${id}/`);
  }

async createChat(customerInfo: { name: string; email: string }): Promise<Chat> {
    // Transform the payload to match backend expectations
    const backendPayload = {
      customer_info: {
        customer_name: customerInfo.name,
        customer_email: customerInfo.email
      }
    };
    return post('chats/', backendPayload);
  }
  async assignChatToStaff(chatId: string, staffId: string): Promise<void> {
    await post(`chats/${chatId}/assign/`, { staff_id: staffId });
  }

  async closeChat(chatId: string): Promise<void> {
    await post(`chats/${chatId}/close/`);
  }

  // Message operations
  // sendMessage is removed from here.
  // Real-time message sending is handled directly by the chatStore via WebSocket.
  // The Django Channels consumer will save the message and broadcast it.

  async markMessagesAsRead(chatId: string): Promise<void> {
    await post(`chats/${chatId}/messages/mark_read/`);
  }

  // Staff operations
  async getStaff(): Promise<User[]> {
    // Assuming Django endpoint is /helpdesk/api/users/staff/
    return get('users/staff/');
  }

  async getOnlineStaff(): Promise<User[]> {
    // This can be filtered on the client-side from getStaff()
    // Or, if a specific backend endpoint is needed, it would be:
    // return get('users/online_staff/');
    const allStaff = await this.getStaff();
    return allStaff.filter(s => s.isOnline); // Client-side filtering for now
  }

  // Statistics
  async getStats(): Promise<ChatStats> {
    return
  }

  // Visitors
  async getOnlineVisitors(): Promise<OnlineVisitor[]> {
    return get('visitors/online/');
  }
}

export const chatService = new ChatService();