<template>
  <div class="theme-selector">
    <button class="theme-trigger" @click="toggleDropdown">
      <span class="theme-icon">{{ currentTheme.icon }}</span>
      <span class="theme-name">{{ currentTheme.name }}</span>
      <span class="dropdown-arrow" :class="{ open: isOpen }">▼</span>
    </button>
    
    <transition name="dropdown">
      <div v-if="isOpen" class="theme-dropdown">
        <div
          v-for="theme in themes"
          :key="theme.id"
          class="theme-option"
          :class="{ active: theme.id === currentTheme.id }"
          @click="selectTheme(theme.id)"
          @mouseenter="previewTheme(theme.id)"
          @mouseleave="stopPreview"
        >
          <span class="option-icon">{{ theme.icon }}</span>
          <span class="option-name">{{ theme.name }}</span>
          <span v-if="theme.id === currentTheme.id" class="check-mark">✓</span>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useTheme } from '../composables/useTheme'

const { currentTheme, themes, setTheme, preview, stopPreview } = useTheme()
const isOpen = ref(false)

function toggleDropdown() {
  isOpen.value = !isOpen.value
}

function selectTheme(themeId: string) {
  setTheme(themeId)
  isOpen.value = false
}

function previewTheme(themeId: string) {
  preview(themeId)
}
</script>

<style scoped>
.theme-selector {
  position: relative;
}

.theme-trigger {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  cursor: pointer;
  transition: all var(--transition-fast);
  color: var(--color-text);
}

.theme-trigger:hover {
  background: var(--color-surface-hover);
  border-color: var(--color-primary);
}

.theme-icon {
  font-size: var(--font-size-lg);
}

.theme-name {
  font-size: var(--font-size-sm);
}

.dropdown-arrow {
  font-size: 10px;
  color: var(--color-text-muted);
  transition: transform var(--transition-fast);
}

.dropdown-arrow.open {
  transform: rotate(180deg);
}

.theme-dropdown {
  position: absolute;
  top: calc(100% + 4px);
  right: 0;
  min-width: 160px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-lg);
  overflow: hidden;
  z-index: var(--z-index-dropdown);
}

.theme-option {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  padding: var(--spacing-md);
  cursor: pointer;
  transition: background var(--transition-fast);
  color: var(--color-text);
}

.theme-option:hover {
  background: var(--color-surface-hover);
}

.theme-option.active {
  background: var(--color-primary-light);
  background: rgba(74, 158, 255, 0.1);
}

.option-icon {
  font-size: var(--font-size-lg);
}

.option-name {
  flex: 1;
  font-size: var(--font-size-base);
}

.check-mark {
  color: var(--color-primary);
  font-weight: bold;
}

.dropdown-enter-active,
.dropdown-leave-active {
  transition: all var(--transition-fast);
}

.dropdown-enter-from,
.dropdown-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
</style>
