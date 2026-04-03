<template>
  <div v-if="!hasStartedChat">
    <!-- Show Pre-Chat Form -->
    <PreChatForm @start-chat="handleStartChat" />
  </div>

  <div v-else class="fixed bottom-5 right-5 z-50">
    <!-- Chat Bubble -->
    <button 
      v-if="!isOpen" 
      @click="toggleChat"
      class="bg-[#0a2a4b] text-white rounded-full p-4 shadow-lg hover:bg-[#0a2a4b] focus:outline-none focus:ring-2 focus:ring-[#0a2a4b] focus:ring-opacity-50 transition-transform transform hover:scale-110"
    >
      <MessageSquare :size="32" />
    </button>

    <!-- Chat Window -->
    <div 
      v-if="isOpen"
      class="w-[90vw] h-[70vh] md:w-[400px] md:h-[600px] bg-white rounded-2xl shadow-2xl flex flex-col transition-all duration-300 ease-in-out"
    >
      <!-- Header -->
      <header class="bg-[#09263a] text-white p-4 flex justify-between items-center rounded-t-2xl shadow-md">
        <div>
          <h2 class="text-lg font-semibold">Customer Support</h2>
          <span 
            class="text-xs flex items-center mt-1" 
            :class="{ 
              'text-green-300': connectionState === 'OPEN', 
              'text-yellow-300': connectionState === 'CONNECTING', 
              'text-red-300': connectionState === 'CLOSED' 
            }"
          >
            <span 
              class="w-2 h-2 rounded-full mr-2" 
              :class="{ 
                'bg-green-400': connectionState === 'OPEN', 
                'bg-yellow-400': connectionState === 'CONNECTING', 
                'bg-red-400': connectionState === 'CLOSED' 
              }"
            ></span>
            {{ connectionState === 'OPEN' ? 'Online' : (connectionState === 'CONNECTING' ? 'Connecting...' : 'Offline') }}
          </span>
        </div>
        <button @click="toggleChat" class="text-white hover:text-blue-200">
          <X :size="24" />
        </button>
      </header>

      <!-- Message List -->
      <div 
        ref="messageListEl" 
        class="flex-1 p-4 overflow-y-auto bg-gray-50"
      >
        <div 
          v-for="message in messages" 
          :key="message.id" 
          class="mb-4"
        >
          <div 
            class="flex items-end" 
            :class="{ 'justify-end': isMyMessage(message) }"
          >
            <div 
              class="flex flex-col space-y-1 text-sm max-w-xs mx-2" 
              :class="{ 
                'order-2 items-start': !isMyMessage(message), 
                'order-1 items-end': isMyMessage(message) 
              }"
            >
              <!-- Message Content -->
              <div v-if="message.content && !message.content.startsWith('[Shared')">
                <span 
                  class="px-4 py-2 rounded-2xl inline-block" 
                  :class="{ 
                    'rounded-bl-none bg-gray-200 text-gray-800': !isMyMessage(message), 
                    'rounded-br-none bg-[#09263a] text-white': isMyMessage(message) 
                  }"
                >
                  {{ message.content }}
                </span>
              </div>
              
              <!-- Attachments -->
              <div v-if="message.attachments && message.attachments.length > 0" class="space-y-2">
                <div 
                  v-for="attachment in message.attachments" 
                  :key="attachment.id"
                  class="rounded-lg overflow-hidden"
                  :class="{
                    'bg-gray-100': !isMyMessage(message),
                    'bg-[#0a3d5c]': isMyMessage(message)
                  }"
                >
                  <!-- Image Attachment -->
                  <div v-if="attachment.file_type === 'image' || isImageMimeType(attachment.mime_type)" class="relative">
                    <img 
                      :src="attachment.file_url" 
                      :alt="attachment.file_name"
                      class="max-w-full max-h-48 rounded-lg cursor-pointer hover:opacity-90 transition-opacity"
                      @click="openAttachment(attachment)"
                    />
                  </div>
                  
                  <!-- PDF Attachment -->
                  <div 
                    v-else-if="attachment.file_type === 'pdf'" 
                    class="p-3 flex items-center gap-3 cursor-pointer hover:bg-opacity-80 transition-colors"
                    @click="openAttachment(attachment)"
                  >
                    <div class="w-10 h-10 bg-red-500 rounded-lg flex items-center justify-center flex-shrink-0">
                      <FileText :size="20" class="text-white" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium truncate" :class="isMyMessage(message) ? 'text-white' : 'text-gray-800'">
                        {{ attachment.file_name }}
                      </p>
                      <p class="text-xs" :class="isMyMessage(message) ? 'text-blue-200' : 'text-gray-500'">
                        {{ formatFileSize(attachment.file_size) }}
                      </p>
                    </div>
                    <Download :size="18" :class="isMyMessage(message) ? 'text-white' : 'text-gray-500'" />
                  </div>
                  
                  <!-- Other File Types (fallback) -->
                  <div 
                    v-else
                    class="p-3 flex items-center gap-3 cursor-pointer hover:bg-opacity-80 transition-colors"
                    @click="openAttachment(attachment)"
                  >
                    <div class="w-10 h-10 bg-gray-500 rounded-lg flex items-center justify-center flex-shrink-0">
                      <Download :size="20" class="text-white" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <p class="text-sm font-medium truncate" :class="isMyMessage(message) ? 'text-white' : 'text-gray-800'">
                        {{ attachment.file_name }}
                      </p>
                      <p class="text-xs" :class="isMyMessage(message) ? 'text-blue-200' : 'text-gray-500'">
                        {{ formatFileSize(attachment.file_size) }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div 
              class="w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center text-sm font-bold text-gray-600" 
              :class="{ 
                'order-1': !isMyMessage(message), 
                'order-2': isMyMessage(message) 
              }"
            >
              {{ getMessageInitial(message) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Message Input -->
      <footer class="p-4 border-t border-gray-200 bg-white rounded-b-2xl">
        <!-- Attachment Preview -->
        <div v-if="selectedFile" class="mb-3 p-2 bg-gray-100 rounded-lg flex items-center justify-between">
          <div class="flex items-center gap-2 min-w-0">
            <div v-if="isImageFile(selectedFile)" class="w-10 h-10 rounded overflow-hidden flex-shrink-0">
              <img :src="filePreviewUrl" alt="Preview" class="w-full h-full object-cover" />
            </div>
            <div v-else class="w-10 h-10 bg-red-500 rounded flex items-center justify-center flex-shrink-0">
              <FileText :size="18" class="text-white" />
            </div>
            <div class="min-w-0">
              <p class="text-sm text-gray-700 truncate">{{ selectedFile.name }}</p>
              <p class="text-xs text-gray-500">{{ formatFileSize(selectedFile.size) }}</p>
            </div>
          </div>
          <button @click="clearSelectedFile" class="p-1 hover:bg-gray-200 rounded transition-colors">
            <X :size="16" class="text-gray-500" />
          </button>
        </div>
        
        <div class="flex items-center gap-2">
          <!-- Emoji Picker Button -->
          <div class="relative" ref="emojiPickerRef">
            <button
              @click="showEmojiPicker = !showEmojiPicker"
              class="p-2.5 rounded-full hover:bg-gray-100 text-gray-500 transition-colors"
              :class="{ 'bg-yellow-100 text-yellow-600': showEmojiPicker }"
              :disabled="connectionState !== 'OPEN' || isUploading"
              title="Add emoji"
            >
              <Smile :size="20" />
            </button>
            
            <!-- Emoji Picker Dropdown -->
            <div
              v-if="showEmojiPicker"
              class="absolute bottom-full left-0 mb-2 w-72 bg-white rounded-lg shadow-xl border border-gray-200 z-50 overflow-hidden"
            >
              <div class="max-h-64 overflow-y-auto p-2">
                <div v-for="category in emojiCategories" :key="category.name" class="mb-2">
                  <p class="text-xs font-medium text-gray-500 mb-1 px-1">{{ category.name }}</p>
                  <div class="flex flex-wrap gap-0.5">
                    <button
                      v-for="emoji in category.emojis"
                      :key="emoji"
                      @click="insertEmoji(emoji)"
                      class="w-7 h-7 flex items-center justify-center text-lg rounded hover:bg-gray-100 hover:scale-110 transition-transform"
                    >
                      {{ emoji }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- File Upload Button -->
          <button
            @click="triggerFileInput"
            class="p-2.5 rounded-full hover:bg-gray-100 text-gray-500 transition-colors"
            :disabled="connectionState !== 'OPEN' || isUploading"
            title="Attach file"
          >
            <Paperclip :size="20" />
          </button>
          <input
            ref="fileInput"
            type="file"
            @change="handleFileSelect"
            accept="image/png,image/jpeg,image/gif,image/webp,application/pdf"
            class="hidden"
          />
          
          <div class="relative flex-1">
            <input
              type="text"
              v-model="newMessage"
              @keyup.enter="handleSendMessage"
              placeholder="Type your message..."
              class="w-full py-3 pl-4 pr-12 text-sm bg-gray-100 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              :disabled="connectionState !== 'OPEN' || isUploading"
            />
            <button 
              @click="handleSendMessage" 
              class="absolute right-2 top-1/2 -translate-y-1/2 bg-[#09263a] text-white rounded-full p-2.5 hover:bg-[#0a3d5c] focus:outline-none transition-transform transform hover:scale-110" 
              :disabled="connectionState !== 'OPEN' || isUploading || (!newMessage.trim() && !selectedFile)"
            >
              <Loader v-if="isUploading" :size="18" class="animate-spin" />
              <Send v-else :size="18" />
            </button>
          </div>
        </div>
      </footer>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue';
import { useChatStore } from '@/store/chat';
import { auth } from '@/store/auth';
import { Send, MessageSquare, X, FileText, Download, Paperclip, Loader, Smile } from 'lucide-vue-next';
import PreChatForm from './PreChatForm.vue';

const chatStore = useChatStore();
const hasStartedChat = ref(false);

const newMessage = ref('');
const messageListEl = ref(null);

// File upload state
const fileInput = ref(null);
const selectedFile = ref(null);
const filePreviewUrl = ref(null);
const isUploading = ref(false);

// Emoji picker state
const showEmojiPicker = ref(false);
const emojiPickerRef = ref(null);

// Common emoji categories
const emojiCategories = [
  { name: 'Smileys', emojis: ['😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '😉', '😌', '😍', '🥰', '😘', '😋', '😛', '😜', '🤪', '😝', '🤗', '🤔', '🤐', '😏', '😒', '🙄', '😬', '😮', '😯', '😲', '😳', '🥺', '😢', '😭', '😤', '😠', '😡'] },
  { name: 'Gestures', emojis: ['👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙', '👋', '🖐️', '✋', '🖖', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '💪'] },
  { name: 'Hearts', emojis: ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '💕', '💞', '💓', '💗', '💖', '💘', '💝'] },
  { name: 'Symbols', emojis: ['✅', '❌', '⚠️', '❓', '❗', '💯', '🔥', '💡', '🎯', '🏆', '🎉', '🎊', '✨', '💫', '⭐', '🌟'] }
];

// Computed properties
const isOpen = computed(() => chatStore.isWidgetOpen);
const messages = computed(() => chatStore.messages);
const connectionState = computed(() => chatStore.connectionState);
const currentUserId = computed(() => auth.userProfile?.id);

// Auto-scrolling function
const scrollToBottom = async () => {
  await nextTick();
  if (messageListEl.value) {
    messageListEl.value.scrollTop = messageListEl.value.scrollHeight;
  }
};

// Watchers
watch(messages, scrollToBottom, { deep: true });

// Lifecycle hooks
onMounted(() => {
  if (isOpen.value) {
    scrollToBottom();
  }
});

// Methods
const handleStartChat = async (guestInfo) => {
  try {
    await chatStore.startOrResumeConversation(guestInfo);
    hasStartedChat.value = true;
    chatStore.isWidgetOpen = true;
  } catch (error) {
    console.error('Failed to start chat:', error);
  }
};

const handleSendMessage = async () => {
  const trimmedMessage = newMessage.value.trim();
  const hasFile = selectedFile.value !== null;

  if (!trimmedMessage && !hasFile) return;

  // If there's a file, upload it
  if (hasFile) {
    isUploading.value = true;
    try {
      const conversationId = localStorage.getItem('conversationId');
      if (!conversationId) {
        console.error('No conversation ID found');
        return;
      }
      
      const result = await chatStore.uploadAttachment(
        conversationId,
        selectedFile.value,
        trimmedMessage || null
      );

      if (result.success) {
        clearSelectedFile();
        newMessage.value = '';
      } else {
        console.error('Upload failed:', result.error);
        alert('Failed to upload file. Please try again.');
      }
    } catch (error) {
      console.error('Upload error:', error);
      alert('An error occurred while uploading the file.');
    } finally {
      isUploading.value = false;
    }
  } else if (trimmedMessage) {
    chatStore.sendMessage(trimmedMessage);
    newMessage.value = '';
  }
};

// File handling methods
const triggerFileInput = () => {
  fileInput.value?.click();
};

const handleFileSelect = (event) => {
  const file = event.target.files?.[0];
  if (!file) return;

  // Validate file type
  const allowedTypes = ['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'application/pdf'];
  if (!allowedTypes.includes(file.type)) {
    alert('File type not allowed. Please upload an image (PNG, JPG, GIF, WebP) or PDF.');
    return;
  }

  // Validate file size (10MB max)
  const maxSize = 10 * 1024 * 1024;
  if (file.size > maxSize) {
    alert('File size exceeds 10MB limit.');
    return;
  }

  selectedFile.value = file;

  // Create preview URL for images
  if (file.type.startsWith('image/')) {
    filePreviewUrl.value = URL.createObjectURL(file);
  } else {
    filePreviewUrl.value = null;
  }
};

const clearSelectedFile = () => {
  if (filePreviewUrl.value) {
    URL.revokeObjectURL(filePreviewUrl.value);
  }
  selectedFile.value = null;
  filePreviewUrl.value = null;
  if (fileInput.value) {
    fileInput.value.value = '';
  }
};

const isImageFile = (file) => {
  return file?.type?.startsWith('image/');
};

// Emoji methods
const insertEmoji = (emoji) => {
  newMessage.value += emoji;
  showEmojiPicker.value = false;
};

// Close emoji picker when clicking outside
const handleClickOutside = (event) => {
  if (emojiPickerRef.value && !emojiPickerRef.value.contains(event.target)) {
    showEmojiPicker.value = false;
  }
};

const toggleChat = () => {
  chatStore.toggleWidget();
};

// Check if user already has an active conversation on mount
onMounted(() => {
  const existingId = localStorage.getItem('conversationId');
  if (existingId) {
    hasStartedChat.value = true;
  }
  
  // Listen for emoji picker click outside
  document.addEventListener('click', handleClickOutside);
});

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside);
});

// Helper to check if message is from current user
// For anonymous users, we check if user is null (our message) or has an id (staff message)
const isMyMessage = (message) => {
  // If we're not authenticated (anonymous)
  if (!currentUserId.value) {
    // Our messages have user=null, staff messages have user object
    return !message.user;
  }
  // If we're authenticated, check user ID
  return message.user && message.user.id === currentUserId.value;
};

// Helper to get message sender initial
const getMessageInitial = (message) => {
  // If user is Guest and we have guest_name, use that
  if (message.user?.username === 'Guest' && message.guest_name) {
    return message.guest_name.charAt(0).toUpperCase();
  }
  // If message has a user with username
  if (message.user && message.user.username) {
    return message.user.username.charAt(0).toUpperCase();
  }
  // For anonymous/guest users without guest_name
  return 'G';
};

// Attachment helper methods
const openAttachment = (attachment) => {
  if (attachment.file_url) {
    window.open(attachment.file_url, '_blank');
  }
};

const formatFileSize = (bytes) => {
  if (!bytes) return '0 B';
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
};

const isImageMimeType = (mimeType) => {
  if (!mimeType) return false;
  return mimeType.startsWith('image/');
};
</script>