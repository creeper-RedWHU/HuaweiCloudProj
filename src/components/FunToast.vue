<template>
  <div class="toast-container">
    <transition-group name="toast">
      <div
        v-for="toast in toasts"
        :key="toast.id"
        class="fun-toast"
        :class="[`toast-${toast.type}`]"
        @mouseenter="pauseTimer(toast.id)"
        @mouseleave="resumeTimer(toast.id)"
      >
        <div class="toast-content">
          <span class="toast-message">{{ toast.message }}</span>
        </div>
        <button class="toast-close" @click="removeToast(toast.id)">✕</button>
        <div class="toast-progress" :style="{ animationDuration: `${toast.duration}ms` }"></div>
      </div>
    </transition-group>
  </div>
</template>

<script setup lang="ts">
import { useToast } from '../composables/useToast'

const { toasts, remove } = useToast()

const pausedTimers = new Map<string, number>()

function removeToast(id: string) {
  remove(id)
}

function pauseTimer(id: string) {
  const toast = toasts.value.find(t => t.id === id)
  if (toast) {
    const elapsed = Date.now() - toast.createdAt
    const remaining = toast.duration - elapsed
    pausedTimers.set(id, remaining)
  }
}

function resumeTimer(id: string) {
  const remaining = pausedTimers.get(id)
  if (remaining) {
    setTimeout(() => {
      remove(id)
    }, remaining)
    pausedTimers.delete(id)
  }
}
</script>

<style scoped>
.toast-container {
  position: fixed;
  top: 80px;
  right: 20px;
  z-index: var(--z-index-toast);
  display: flex;
  flex-direction: column;
  gap: var(--spacing-sm);
  pointer-events: none;
}

.fun-toast {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
  min-width: 280px;
  max-width: 400px;
  padding: var(--spacing-md) var(--spacing-lg);
  background: var(--color-surface);
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-xl);
  pointer-events: auto;
  position: relative;
  overflow: hidden;
}

.toast-content {
  flex: 1;
  display: flex;
  align-items: center;
}

.toast-message {
  font-size: var(--font-size-md);
  color: var(--color-text);
  line-height: 1.4;
}

.toast-close {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  background: transparent;
  border: none;
  border-radius: var(--radius-full);
  cursor: pointer;
  color: var(--color-text-muted);
  font-size: 12px;
  transition: all var(--transition-fast);
}

.toast-close:hover {
  background: var(--color-surface-hover);
  color: var(--color-text);
}

.toast-progress {
  position: absolute;
  bottom: 0;
  left: 0;
  height: 3px;
  background: var(--color-primary);
  animation: progress linear forwards;
}

@keyframes progress {
  from {
    width: 100%;
  }
  to {
    width: 0%;
  }
}

.toast-taskAdd { border-left: 4px solid var(--color-primary); }
.toast-taskDelete { border-left: 4px solid var(--color-danger); }
.toast-taskComplete { border-left: 4px solid var(--color-success); }
.toast-taskMove { border-left: 4px solid var(--color-info); }
.toast-themeChange { border-left: 4px solid var(--color-secondary); }
.toast-reset { border-left: 4px solid var(--color-warning); }
.toast-star { border-left: 4px solid var(--color-warning); }
.toast-unstar { border-left: 4px solid var(--color-text-muted); }

.toast-enter-active {
  animation: toast-in 0.4s cubic-bezier(0.68, -0.55, 0.265, 1.55);
}

.toast-leave-active {
  animation: toast-out 0.3s ease-in;
}

@keyframes toast-in {
  from {
    opacity: 0;
    transform: translateX(100px) scale(0.8);
  }
  to {
    opacity: 1;
    transform: translateX(0) scale(1);
  }
}

@keyframes toast-out {
  from {
    opacity: 1;
    transform: translateX(0) scale(1);
  }
  to {
    opacity: 0;
    transform: translateX(50px) scale(0.9);
  }
}
</style>
