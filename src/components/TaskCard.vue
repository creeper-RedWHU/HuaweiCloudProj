<template>
  <div 
    class="task-card" 
    :class="[{ 'is-starred': task.starred, 'is-urgent': task.urgent, 'is-done': task.columnId === 'done' }]"
    draggable="true"
    @dragstart="onDragStart" 
    @dragend="onDragEnd"
  >
    <div class="card-status-bar" :class="`status-${task.columnId}`"></div>
    <div class="card-content">
      <div class="card-header">
        <span class="card-title">{{ task.title }}</span>
        <div class="card-actions">
          <button 
            class="btn-icon btn-star" 
            :class="{ active: task.starred }" 
            @click.stop="$emit('toggle', task.id, 'starred')"
            title="星标"
          >★</button>
          <button 
            class="btn-icon btn-urgent" 
            :class="{ active: task.urgent }" 
            @click.stop="$emit('toggle', task.id, 'urgent')"
            title="紧急"
          >!</button>
          <button 
            class="btn-icon btn-delete" 
            @click.stop="$emit('remove', task.id)" 
            title="删除"
          >×</button>
        </div>
      </div>
      <p v-if="task.description" class="card-desc">{{ task.description }}</p>
      <div class="card-footer">
        <span v-if="task.category" class="card-tag" :style="{ background: categoryColor }">
          {{ task.category }}
        </span>
        <span class="card-date" :title="fullDate">{{ relativeTime }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { formatRelativeTime, formatDateTime } from '../utils/timeFormat'

const CATEGORY_COLORS = [
  '#4a9eff', '#f5a623', '#7ed321', '#bd10e0', '#d0021b', '#50e3c2'
]

const props = defineProps({
  task: { type: Object, required: true }
})

defineEmits(['toggle', 'remove'])

function onDragStart(e) {
  e.dataTransfer.effectAllowed = 'move'
  e.dataTransfer.setData('text/plain', props.task.id)
  e.target.classList.add('dragging')
}

function onDragEnd(e) {
  e.target.classList.remove('dragging')
}

const relativeTime = computed(() => formatRelativeTime(props.task.createdAt))
const fullDate = computed(() => formatDateTime(props.task.createdAt))

const categoryColor = computed(() => {
  if (!props.task.category) return '#999'
  let hash = 0
  for (const ch of props.task.category) {
    hash = ((hash << 5) - hash + ch.charCodeAt(0)) | 0
  }
  return CATEGORY_COLORS[Math.abs(hash) % CATEGORY_COLORS.length]
})
</script>

<style scoped>
.task-card {
  position: relative;
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  overflow: hidden;
  margin-bottom: var(--spacing-sm);
  box-shadow: var(--shadow-sm);
  cursor: grab;
  transition: all var(--transition-fast);
}

.task-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}

.task-card:active {
  cursor: grabbing;
}

.task-card.dragging {
  opacity: 0.5;
  transform: scale(0.95);
}

.card-status-bar {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 5px;
  transition: width var(--transition-fast);
}

.task-card:hover .card-status-bar {
  width: 6px;
}

.status-todo { background: var(--color-primary); }
.status-doing { background: var(--color-warning); }
.status-done { background: var(--color-success); }

.task-card.is-starred .card-status-bar {
  background: var(--color-warning);
  width: 6px;
}

.task-card.is-urgent .card-status-bar {
  background: var(--color-danger);
  width: 7px;
}

.task-card.is-urgent {
  box-shadow: 0 0 0 2px var(--color-danger), var(--shadow-md);
}

.card-content {
  padding: var(--spacing-md);
  padding-left: calc(var(--spacing-md) + 5px);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--spacing-sm);
}

.card-title {
  font-weight: 600;
  font-size: var(--font-size-md);
  color: var(--color-text);
  word-break: break-word;
  flex: 1;
  line-height: 1.4;
}

.task-card.is-done .card-title {
  opacity: 0.7;
}

.card-actions {
  display: flex;
  gap: 4px;
  flex-shrink: 0;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: var(--font-size-lg);
  color: var(--color-text-muted);
  padding: 4px 8px;
  border-radius: var(--radius-sm);
  transition: all var(--transition-fast);
  line-height: 1;
}

.btn-icon:hover {
  background: var(--color-background-secondary);
}

.btn-star.active {
  color: var(--color-warning);
  animation: star-pulse 0.3s ease;
}

.btn-urgent.active {
  color: var(--color-danger);
}

.btn-delete:hover {
  color: var(--color-danger);
  background: rgba(255, 71, 87, 0.1);
}

@keyframes star-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}

.card-desc {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
  margin: var(--spacing-sm) 0 0;
  line-height: 1.5;
  word-break: break-word;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: var(--spacing-sm);
  gap: var(--spacing-sm);
}

.card-tag {
  font-size: var(--font-size-sm);
  color: #fff;
  padding: 4px var(--spacing-md);
  border-radius: var(--radius-full);
  white-space: nowrap;
  font-weight: 500;
}

.card-date {
  font-size: var(--font-size-xs);
  color: var(--color-text-muted);
  white-space: nowrap;
}
</style>
