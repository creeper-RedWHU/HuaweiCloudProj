<template>
  <div class="app">
    <header class="app-header">
      <h1 class="app-title">📋 任务管理看板</h1>
      <div class="header-actions">
        <span class="task-total">共 {{ tasks.length }} 项任务</span>
        <button class="btn btn-add" @click="showModal = true">+ 新增任务</button>
        <button class="btn btn-reset" @click="onReset">重置</button>
      </div>
    </header>

    <main class="kanban-board">
      <KanbanColumn v-for="col in columns" :key="col.id" :column="col"
        :taskList="getTasksByColumn(col.id)" @move="onMoveTask" @toggle="onToggle" @remove="onRemove" />
    </main>

    <AddTaskModal v-if="showModal" :columns="columns" :existingCategories="existingCategories" @close="showModal = false"
      @submit="onAddTask" />

    <footer class="app-footer">
      <span>数据自动保存至 localStorage</span>
    </footer>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useKanban } from './composables/useKanban.js'
import KanbanColumn from './components/KanbanColumn.vue'
import AddTaskModal from './components/AddTaskModal.vue'

const {
  columns, tasks, addTask, removeTask, toggleTaskFlag, moveTask, getTasksByColumn, resetBoard
} = useKanban()

const showModal = ref(false)

const existingCategories = computed(() => {
  const cats = new Set(tasks.value.map(t => t.category).filter(Boolean))
  return [...cats]
})

function onAddTask(task) {
  addTask(task)
}

function onMoveTask(taskId, toColumnId, toIndex) {
  moveTask(taskId, toColumnId, toIndex)
}

function onToggle(taskId, flag) {
  toggleTaskFlag(taskId, flag)
}

function onRemove(taskId) {
  removeTask(taskId)
}

function onReset() {
  if (confirm('确定要重置看板吗？所有任务将被清除。')) {
    resetBoard()
  }
}
</script>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.app-header {
  background: #fff;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
  flex-shrink: 0;
}

.app-title {
  margin: 0;
  font-size: 20px;
  color: #333;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.task-total {
  font-size: 13px;
  color: #999;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
  transition: background 0.15s, transform 0.1s;
}

.btn:active {
  transform: scale(0.97);
}

.btn-add {
  background: #4a9eff;
  color: #fff;
}

.btn-add:hover {
  background: #3a8eef;
}

.btn-reset {
  background: #f0f0f0;
  color: #666;
}

.btn-reset:hover {
  background: #e0e0e0;
}

.kanban-board {
  display: flex;
  gap: 16px;
  padding: 20px 24px;
  flex: 1;
  overflow-x: auto;
  align-items: flex-start;
}

.app-footer {
  text-align: center;
  padding: 12px;
  font-size: 12px;
  color: #bbb;
  flex-shrink: 0;
}
</style>
