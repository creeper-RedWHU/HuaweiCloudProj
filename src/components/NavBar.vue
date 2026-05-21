<template>
  <nav class="navbar">
    <div class="navbar-brand">
      <div class="logo">
        <span class="logo-icon">📋</span>
        <span class="logo-text">任务看板</span>
      </div>
    </div>
    
    <div class="navbar-stats">
      <div class="stat-item">
        <span class="stat-label">总计</span>
        <span class="stat-value">{{ totalTasks }}</span>
      </div>
      <div class="stat-divider"></div>
      <div class="stat-item stat-todo">
        <span class="stat-dot"></span>
        <span class="stat-value">{{ todoCount }}</span>
      </div>
      <div class="stat-item stat-doing">
        <span class="stat-dot"></span>
        <span class="stat-value">{{ doingCount }}</span>
      </div>
      <div class="stat-item stat-done">
        <span class="stat-dot"></span>
        <span class="stat-value">{{ doneCount }}</span>
      </div>
    </div>
    
    <div class="navbar-actions">
      <button class="btn btn-primary" @click="$emit('add-task')">
        <span class="btn-icon">+</span>
        <span class="btn-text">新增任务</span>
      </button>
      <button class="btn btn-secondary" @click="$emit('reset')">
        <span class="btn-icon">↻</span>
        <span class="btn-text">重置</span>
      </button>
      <ThemeSelector />
    </div>
  </nav>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import ThemeSelector from './ThemeSelector.vue'

interface Props {
  tasks: Array<{ columnId: string }>
}

const props = defineProps<Props>()

defineEmits<{
  'add-task': []
  'reset': []
}>()

const totalTasks = computed(() => props.tasks.length)

const todoCount = computed(() => 
  props.tasks.filter(t => t.columnId === 'todo').length
)

const doingCount = computed(() => 
  props.tasks.filter(t => t.columnId === 'doing').length
)

const doneCount = computed(() => 
  props.tasks.filter(t => t.columnId === 'done').length
)
</script>

<style scoped>
.navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--spacing-xl);
  padding: var(--spacing-lg) var(--spacing-xl);
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  box-shadow: var(--shadow-sm);
  position: sticky;
  top: 0;
  z-index: var(--z-index-dropdown);
}

.navbar-brand {
  flex-shrink: 0;
}

.logo {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.logo-icon {
  font-size: 32px;
}

.logo-text {
  font-size: var(--font-size-xl);
  font-weight: 600;
  color: var(--color-text);
  letter-spacing: -0.5px;
}

.navbar-stats {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
  padding: var(--spacing-sm) var(--spacing-lg);
  background: var(--color-background);
  border-radius: var(--radius-xl);
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 6px;
}

.stat-label {
  font-size: var(--font-size-xs);
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.stat-value {
  font-size: var(--font-size-md);
  font-weight: 600;
  color: var(--color-text);
}

.stat-divider {
  width: 1px;
  height: 20px;
  background: var(--color-border);
}

.stat-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.stat-todo .stat-dot { background: var(--color-primary); }
.stat-doing .stat-dot { background: var(--color-warning); }
.stat-done .stat-dot { background: var(--color-success); }

.navbar-actions {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
}

.btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: var(--spacing-sm) var(--spacing-lg);
  border: none;
  border-radius: var(--radius-lg);
  font-size: var(--font-size-base);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.btn-icon {
  font-size: var(--font-size-lg);
}

.btn-text {
  font-weight: 500;
}

.btn-primary {
  background: var(--color-primary);
  color: white;
}

.btn-primary:hover {
  background: var(--color-primary-dark);
  transform: translateY(-1px);
  box-shadow: 0 2px 8px var(--color-shadow);
}

.btn-secondary {
  background: var(--color-background-secondary);
  color: var(--color-text-secondary);
}

.btn-secondary:hover {
  background: var(--color-border);
}

@media (max-width: 768px) {
  .navbar {
    flex-wrap: wrap;
    padding: var(--spacing-md);
  }
  
  .navbar-stats {
    order: 3;
    width: 100%;
    justify-content: center;
  }
  
  .btn-text {
    display: none;
  }
  
  .btn {
    padding: var(--spacing-sm);
  }
}
</style>
