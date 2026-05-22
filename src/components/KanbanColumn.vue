<template>
  <div 
    class="kanban-column" 
    @dragover.prevent="onDragOver" 
    @drop="onDrop" 
    @dragleave="onDragLeave"
    :class="{ 'drag-over': isDragOver }"
  >
    <div class="column-header" :style="{ background: headerGradient }">
      <h3 class="column-title">
        <span class="column-dot" :style="{ background: column.color }"></span>
        {{ column.title }}
      </h3>
      <span class="column-count">{{ taskList.length }}</span>
    </div>
    <div class="column-body">
      <TaskCard 
        v-for="task in taskList" 
        :key="task.id" 
        :task="task" 
        @toggle="onToggle" 
        @remove="onRemove" 
      />
      <EmptyState 
        v-if="taskList.length === 0"
        :icon="emptyIcon"
        :title="'暂无任务'"
        :hint="emptyHint"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import TaskCard from './TaskCard.vue'
import EmptyState from './EmptyState.vue'

const props = defineProps({
  column: { type: Object, required: true },
  taskList: { type: Array, required: true }
})

const emit = defineEmits(['move', 'toggle', 'remove'])

const isDragOver = ref(false)

const headerGradient = computed(() => {
  return `linear-gradient(135deg, ${props.column.color}15 0%, ${props.column.color}05 100%)`
})

const emptyIcon = computed(() => {
  const icons = {
    todo: '📝',
    doing: '⚡',
    done: '✅'
  }
  return icons[props.column.id] || '📥'
})

const emptyHint = computed(() => {
  const hints = {
    todo: '点击上方按钮添加新任务',
    doing: '将待办任务拖到这里',
    done: '完成的任务将显示在此'
  }
  return hints[props.column.id] || ''
})

function onDragOver(e) {
  isDragOver.value = true
  e.dataTransfer.dropEffect = 'move'
}

function onDragLeave() {
  isDragOver.value = false
}

function onDrop(e) {
  isDragOver.value = false
  const taskId = e.dataTransfer.getData('text/plain')
  if (taskId) {
    emit('move', taskId, props.column.id, props.taskList.length)
  }
}

function onToggle(taskId, flag) {
  emit('toggle', taskId, flag)
}

function onRemove(taskId) {
  emit('remove', taskId)
}
</script>

<style scoped>
.kanban-column {
  position: relative;
  background: var(--color-background-secondary);
  border-radius: var(--radius-xl);
  min-width: 340px;
  max-width: 400px;
  flex: 1;
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 180px);
  transition: all var(--transition-normal);
  border: 1px solid var(--color-border-light);
}

.kanban-column.drag-over {
  background: var(--color-surface-hover);
  border-color: var(--color-primary);
  box-shadow: 
    0 0 0 2px var(--color-primary-light),
    inset 0 0 30px rgba(74, 158, 255, 0.05);
  transform: scale(1.02);
}

.kanban-column.drag-over::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: var(--radius-xl);
  background: linear-gradient(135deg, 
    transparent 0%, 
    rgba(74, 158, 255, 0.1) 50%, 
    transparent 100%
  );
  animation: shimmer 1.5s infinite;
  pointer-events: none;
}

@keyframes shimmer {
  0% { opacity: 0; }
  50% { opacity: 1; }
  100% { opacity: 0; }
}

.column-header {
  padding: var(--spacing-md) var(--spacing-lg);
  border-bottom: 1px solid var(--color-border-light);
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-radius: var(--radius-xl) var(--radius-xl) 0 0;
}

.column-title {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--color-text);
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  margin: 0;
}

.column-dot {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  flex-shrink: 0;
  box-shadow: 0 2px 4px var(--color-shadow-light);
}

.column-count {
  background: var(--color-surface);
  color: var(--color-text-secondary);
  font-size: var(--font-size-sm);
  font-weight: 600;
  padding: 4px 12px;
  border-radius: var(--radius-full);
  min-width: 32px;
  text-align: center;
}

.column-body {
  padding: var(--spacing-sm);
  overflow-y: auto;
  flex: 1;
}

.column-body::-webkit-scrollbar {
  width: 8px;
}

.column-body::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: 4px;
}

.column-body::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-muted);
}

.column-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-2xl) var(--spacing-lg);
  text-align: center;
}

.empty-icon {
  font-size: 40px;
  margin-bottom: var(--spacing-md);
  opacity: 0.5;
}

.empty-text {
  color: var(--color-text-muted);
  font-size: var(--font-size-base);
  margin-bottom: 4px;
}

.empty-hint {
  color: var(--color-text-muted);
  font-size: var(--font-size-xs);
  opacity: 0.7;
}
</style>
