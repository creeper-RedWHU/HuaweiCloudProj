<template>
  <div class="app">
    <NavBar 
      :tasks="tasks" 
      @add-task="showModal = true" 
      @reset="onReset" 
    />
    
    <main class="kanban-board">
      <KanbanColumn 
        v-for="col in columns" 
        :key="col.id" 
        :column="col"
        :taskList="getTasksByColumn(col.id)" 
        @move="onMoveTask" 
        @toggle="onToggle" 
        @remove="onRemove" 
      />
    </main>

    <AddTaskModal 
      v-if="showModal" 
      :columns="columns" 
      :existingCategories="existingCategories" 
      @close="showModal = false"
      @submit="onAddTask" 
    />

    <FunToast />

    <footer class="app-footer">
      <span class="footer-text">💾 数据自动保存至本地存储</span>
      <span class="footer-divider">|</span>
      <span class="footer-text">🎨 多主题支持</span>
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useKanban } from './composables/useKanban.js'
import { useToast } from './composables/useToast.ts'
import NavBar from './components/NavBar.vue'
import KanbanColumn from './components/KanbanColumn.vue'
import AddTaskModal from './components/AddTaskModal.vue'
import FunToast from './components/FunToast.vue'

const {
  columns, tasks, addTask, removeTask, toggleTaskFlag, moveTask, getTasksByColumn, resetBoard
} = useKanban()

const { show: showToast } = useToast()

const showModal = ref(false)

const existingCategories = computed(() => {
  const cats = new Set(tasks.value.map(t => t.category).filter(Boolean))
  return [...cats]
})

const previousColumnMap = ref(new Map())

watch(tasks, (newTasks) => {
  newTasks.forEach(task => {
    const prevColumn = previousColumnMap.value.get(task.id)
    if (prevColumn && prevColumn !== task.columnId) {
      if (task.columnId === 'done') {
        showToast('taskComplete')
      } else {
        showToast('taskMove')
      }
    }
    previousColumnMap.value.set(task.id, task.columnId)
  })
}, { deep: true })

function onAddTask(task) {
  addTask(task)
  showToast('taskAdd')
}

function onMoveTask(taskId, toColumnId, toIndex) {
  moveTask(taskId, toColumnId, toIndex)
}

function onToggle(taskId, flag) {
  toggleTaskFlag(taskId, flag)
  const task = tasks.value.find(t => t.id === taskId)
  if (task && flag === 'starred') {
    showToast(task.starred ? 'star' : 'unstar')
  }
}

function onRemove(taskId) {
  removeTask(taskId)
  showToast('taskDelete')
}

function onReset() {
  if (confirm('确定要重置看板吗？所有任务将被清除。')) {
    resetBoard()
    previousColumnMap.value.clear()
    showToast('reset')
  }
}
</script>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--color-background);
}

.kanban-board {
  display: flex;
  gap: var(--spacing-lg);
  padding: var(--spacing-xl);
  flex: 1;
  overflow-x: auto;
  align-items: flex-start;
}

.kanban-board::-webkit-scrollbar {
  height: 8px;
}

.kanban-board::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: 4px;
}

.app-footer {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-md);
  padding: var(--spacing-md);
  background: var(--color-surface);
  border-top: 1px solid var(--color-border-light);
  flex-shrink: 0;
}

.footer-text {
  font-size: var(--font-size-xs);
  color: var(--color-text-muted);
}

.footer-divider {
  color: var(--color-border);
  font-size: var(--font-size-xs);
}

@media (max-width: 768px) {
  .kanban-board {
    flex-direction: column;
    padding: var(--spacing-md);
    align-items: stretch;
  }
  
  .app-footer {
    flex-wrap: wrap;
  }
}
</style>
