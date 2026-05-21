<template>
  <div class="task-card" :class="{ 'is-starred': task.starred, 'is-urgent': task.urgent }" draggable="true"
    @dragstart="onDragStart" @dragend="onDragEnd">
    <div class="card-header">
      <span class="card-title">{{ task.title }}</span>
      <div class="card-actions">
        <button class="btn-icon" :class="{ active: task.starred }" @click="$emit('toggle', task.id, 'starred')"
          title="星标">★</button>
        <button class="btn-icon" :class="{ active: task.urgent }" @click="$emit('toggle', task.id, 'urgent')"
          title="紧急">!</button>
        <button class="btn-icon btn-delete" @click="$emit('remove', task.id)" title="删除">×</button>
      </div>
    </div>
    <p v-if="task.description" class="card-desc">{{ task.description }}</p>
    <div class="card-footer">
      <span v-if="task.category" class="card-tag" :style="{ background: categoryColor }">{{ task.category }}</span>
      <span class="card-date">{{ formatDate(task.createdAt) }}</span>
    </div>
  </div>
</template>

<script setup>
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

function formatDate(ts) {
  const d = new Date(ts)
  return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`
}

const categoryColor = (() => {
  if (!props.task.category) return '#999'
  let hash = 0
  for (const ch of props.task.category) hash = ((hash << 5) - hash + ch.charCodeAt(0)) | 0
  return CATEGORY_COLORS[Math.abs(hash) % CATEGORY_COLORS.length]
})()
</script>

<style scoped>
.task-card {
  background: #fff;
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12);
  cursor: grab;
  transition: transform 0.15s, box-shadow 0.15s;
  border-left: 3px solid #4a9eff;
}

.task-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  transform: translateY(-1px);
}

.task-card.is-starred {
  border-left-color: #f5a623;
}

.task-card.is-urgent {
  border-left-color: #d0021b;
}

.task-card.dragging {
  opacity: 0.4;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
}

.card-title {
  font-weight: 600;
  font-size: 14px;
  color: #333;
  word-break: break-word;
  flex: 1;
}

.card-actions {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
}

.btn-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
  color: #ccc;
  padding: 2px 4px;
  border-radius: 4px;
  transition: color 0.15s, background 0.15s;
  line-height: 1;
}

.btn-icon:hover {
  background: #f0f0f0;
}

.btn-icon.active {
  color: #f5a623;
}

.btn-icon.btn-delete:hover {
  color: #d0021b;
}

.card-desc {
  font-size: 12px;
  color: #666;
  margin: 6px 0 0;
  line-height: 1.4;
  word-break: break-word;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
  gap: 8px;
}

.card-tag {
  font-size: 11px;
  color: #fff;
  padding: 1px 8px;
  border-radius: 10px;
  white-space: nowrap;
}

.card-date {
  font-size: 11px;
  color: #999;
  white-space: nowrap;
}
</style>
