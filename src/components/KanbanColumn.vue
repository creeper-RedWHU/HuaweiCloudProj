<template>
  <div class="kanban-column" @dragover.prevent="onDragOver" @drop="onDrop" @dragleave="onDragLeave"
    :class="{ 'drag-over': isDragOver }">
    <div class="column-header" :style="{ borderBottomColor: column.color }">
      <h3 class="column-title">
        <span class="column-dot" :style="{ background: column.color }"></span>
        {{ column.title }}
        <span class="column-count">{{ taskList.length }}</span>
      </h3>
    </div>
    <div class="column-body">
      <TaskCard v-for="task in taskList" :key="task.id" :task="task" @toggle="onToggle" @remove="onRemove" />
      <div v-if="taskList.length === 0" class="column-empty">拖拽任务到此处</div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import TaskCard from './TaskCard.vue'

const props = defineProps({
  column: { type: Object, required: true },
  taskList: { type: Array, required: true }
})

const emit = defineEmits(['move', 'toggle', 'remove'])

const isDragOver = ref(false)

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
  background: #f7f8fa;
  border-radius: 10px;
  min-width: 280px;
  max-width: 320px;
  flex: 1;
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 120px);
  transition: background 0.2s;
}

.kanban-column.drag-over {
  background: #e8f0fe;
}

.column-header {
  padding: 12px 16px;
  border-bottom: 3px solid #ddd;
  margin: 0 8px;
}

.column-title {
  font-size: 15px;
  font-weight: 600;
  color: #333;
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0;
}

.column-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.column-count {
  background: #e0e0e0;
  color: #666;
  font-size: 12px;
  font-weight: 500;
  padding: 1px 7px;
  border-radius: 10px;
  margin-left: auto;
}

.column-body {
  padding: 8px;
  overflow-y: auto;
  flex: 1;
}

.column-empty {
  text-align: center;
  color: #bbb;
  font-size: 13px;
  padding: 20px 0;
}
</style>
