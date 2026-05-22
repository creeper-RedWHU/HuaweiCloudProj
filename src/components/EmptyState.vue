<template>
  <div class="empty-state">
    <div class="empty-illustration">
      <div class="floating-elements">
        <div class="float-item item-1">📋</div>
        <div class="float-item item-2">✨</div>
        <div class="float-item item-3">🎯</div>
        <div class="float-item item-4">💡</div>
      </div>
      <div class="main-icon">
        <span class="icon">{{ icon }}</span>
        <div class="pulse-ring"></div>
        <div class="pulse-ring delay-1"></div>
        <div class="pulse-ring delay-2"></div>
      </div>
    </div>
    <div class="empty-content">
      <h3 class="empty-title">{{ title }}</h3>
      <p class="empty-hint">{{ hint }}</p>
      <button v-if="actionText" class="empty-action" @click="$emit('action')">
        <span class="action-icon">{{ actionIcon }}</span>
        <span>{{ actionText }}</span>
      </button>
    </div>
  </div>
</template>

<script setup>
defineProps({
  icon: { type: String, default: '📥' },
  title: { type: String, default: '暂无任务' },
  hint: { type: String, default: '拖拽任务到此处' },
  actionText: { type: String, default: '' },
  actionIcon: { type: String, default: '+' }
})

defineEmits(['action'])
</script>

<style scoped>
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-2xl) var(--spacing-lg);
  text-align: center;
}

.empty-illustration {
  position: relative;
  width: 120px;
  height: 120px;
  margin-bottom: var(--spacing-xl);
}

.main-icon {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.main-icon .icon {
  font-size: 48px;
  animation: icon-float 3s ease-in-out infinite;
}

@keyframes icon-float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

.pulse-ring {
  position: absolute;
  inset: 0;
  border: 2px solid var(--color-primary);
  border-radius: 50%;
  opacity: 0;
  animation: pulse-expand 2s ease-out infinite;
}

.pulse-ring.delay-1 {
  animation-delay: 0.6s;
}

.pulse-ring.delay-2 {
  animation-delay: 1.2s;
}

@keyframes pulse-expand {
  0% {
    transform: scale(0.8);
    opacity: 0.6;
  }
  100% {
    transform: scale(1.5);
    opacity: 0;
  }
}

.floating-elements {
  position: absolute;
  inset: -20px;
}

.float-item {
  position: absolute;
  font-size: 20px;
  animation: float-around 4s ease-in-out infinite;
}

.item-1 {
  top: 0;
  left: 50%;
  animation-delay: 0s;
}

.item-2 {
  top: 50%;
  right: 0;
  animation-delay: 1s;
}

.item-3 {
  bottom: 0;
  left: 50%;
  animation-delay: 2s;
}

.item-4 {
  top: 50%;
  left: 0;
  animation-delay: 3s;
}

@keyframes float-around {
  0%, 100% {
    transform: translateY(0) scale(1);
    opacity: 0.6;
  }
  50% {
    transform: translateY(-10px) scale(1.1);
    opacity: 1;
  }
}

.empty-content {
  max-width: 200px;
}

.empty-title {
  margin: 0 0 8px;
  font-size: var(--font-size-md);
  font-weight: 600;
  color: var(--color-text);
}

.empty-hint {
  margin: 0;
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
  line-height: 1.5;
}

.empty-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  margin-top: var(--spacing-md);
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-primary);
  color: white;
  border: none;
  border-radius: var(--radius-lg);
  font-size: var(--font-size-sm);
  font-weight: 500;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.empty-action:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(74, 158, 255, 0.3);
}

.action-icon {
  font-size: 16px;
}

@media (prefers-reduced-motion: reduce) {
  .main-icon .icon,
  .pulse-ring,
  .float-item {
    animation: none;
  }
  
  .pulse-ring {
    opacity: 0.3;
    transform: scale(1.2);
  }
}
</style>
