const STORAGE_KEY = 'task-kanban-data'

const DEFAULT_COLUMNS = [
  { id: 'todo', title: '待办', color: '#4a9eff' },
  { id: 'doing', title: '进行中', color: '#f5a623' },
  { id: 'done', title: '已完成', color: '#7ed321' }
]

export function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const data = JSON.parse(raw)
      if (data.columns && data.tasks) return data
    }
  } catch {}
  return { columns: DEFAULT_COLUMNS, tasks: [] }
}

export function saveState(state) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state))
  } catch {}
}

export function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8)
}

export { DEFAULT_COLUMNS, STORAGE_KEY }
