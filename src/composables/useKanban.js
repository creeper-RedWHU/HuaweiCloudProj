import { ref, watch } from 'vue'
import { loadState, saveState, DEFAULT_COLUMNS } from '../utils/storage.js'

export function useKanban() {
  const state = loadState()
  const columns = ref(state.columns)
  const tasks = ref(state.tasks)

  watch([columns, tasks], () => {
    saveState({ columns: columns.value, tasks: tasks.value })
  }, { deep: true })

  function addTask(task) {
    tasks.value.push(task)
  }

  function removeTask(taskId) {
    tasks.value = tasks.value.filter(t => t.id !== taskId)
  }

  function updateTask(taskId, updates) {
    const idx = tasks.value.findIndex(t => t.id === taskId)
    if (idx !== -1) {
      tasks.value[idx] = { ...tasks.value[idx], ...updates }
    }
  }

  function toggleTaskFlag(taskId, flag) {
    const task = tasks.value.find(t => t.id === taskId)
    if (task) {
      task[flag] = !task[flag]
    }
  }

  function moveTask(taskId, toColumnId, toIndex) {
    const task = tasks.value.find(t => t.id === taskId)
    if (!task) return
    task.columnId = toColumnId
    const columnTasks = tasks.value.filter(t => t.columnId === toColumnId && t.id !== taskId)
    columnTasks.splice(toIndex, 0, task)
    const otherTasks = tasks.value.filter(t => t.columnId !== toColumnId)
    tasks.value = [...otherTasks, ...columnTasks]
  }

  function getTasksByColumn(columnId) {
    return tasks.value.filter(t => t.columnId === columnId)
  }

  function resetBoard() {
    columns.value = DEFAULT_COLUMNS
    tasks.value = []
  }

  return {
    columns,
    tasks,
    addTask,
    removeTask,
    updateTask,
    toggleTaskFlag,
    moveTask,
    getTasksByColumn,
    resetBoard
  }
}
