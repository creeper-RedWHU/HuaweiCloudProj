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
      <div v-if="taskList.length === 0" class="column-empty">
        <div class="empty-icon">📥</div>
        <div class="empty-text">拖拽任务到此处</div>
        <div class="empty-hint">{{ emptyHint }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import TaskCard from './TaskCard.vue'

const props = defineProps({
  column: { type: Object, required: true },
  taskList: { type: Array, required: true }
})

const emit = defineEmits(['move', 'toggle', 'remove'])

const isDragOver = ref(false)

const headerGradient = computed(() => {
  return `linear-gradient(135deg, ${props.column.color}15 0%, ${props.column.color}05 100%)`
})

const emptyHint = computed(() => {
  const hints = {
    todo: '添加新的待办任务',
    doing: '开始处理任务',
    done: '完成的任务会显示在这里'
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
  background: var(--color-background-secondary);
  border-radius: var(--radius-xl);
  min-width: 300px;
  max-width: 340px;
  flex: 1;
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 160px);
  transition: all var(--transition-normal);
  border: 1px solid var(--color-border-light);
}

.kanban-column.drag-over {
  background: var(--color-surface-hover);
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px var(--color-primary-light);
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
  width: 12px;
  height: 12px;
  border-radius: 50%;
  flex-shrink: 0;
  box-shadow: 0 2px 4px var(--color-shadow-light);
}

.column-count {
  background: var(--color-surface);
  color: var(--color-text-secondary);
  font-size: var(--font-size-sm);
  font-weight: 600;
  padding: 2px 10px;
  border-radius: var(--radius-full);
  min-width: 28px;
  text-align: center;
}

.column-body {
  padding: var(--spacing-sm);
  overflow-y: auto;
  flex: 1;
}

.column-body::-webkit-scrollbar {
  width: 6px;
}

.column-body::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: 3px;
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
  font-size: 32px;
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
