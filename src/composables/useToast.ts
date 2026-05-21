import { ref, computed } from 'vue'
import { getRandomMessage, type ToastType } from '../config/toastMessages'

export interface ToastItem {
  id: string
  message: string
  type: ToastType
  createdAt: number
  duration: number
}

const toasts = ref<ToastItem[]>([])
let toastId = 0

export function useToast() {
  function show(type: ToastType, customMessage?: string, duration: number = 3000) {
    const message = customMessage || getRandomMessage(type)
    const id = `toast-${++toastId}`
    
    const toast: ToastItem = {
      id,
      message,
      type,
      createdAt: Date.now(),
      duration
    }
    
    toasts.value.push(toast)
    
    if (duration > 0) {
      setTimeout(() => {
        remove(id)
      }, duration)
    }
    
    return id
  }
  
  function remove(id: string) {
    const index = toasts.value.findIndex(t => t.id === id)
    if (index !== -1) {
      toasts.value.splice(index, 1)
    }
  }
  
  function clear() {
    toasts.value = []
  }
  
  function success(message?: string) {
    return show('taskComplete', message)
  }
  
  function error(message: string) {
    return show('taskDelete', message, 4000)
  }
  
  const count = computed(() => toasts.value.length)
  
  return {
    toasts,
    count,
    show,
    remove,
    clear,
    success,
    error
  }
}
