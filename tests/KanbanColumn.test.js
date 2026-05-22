import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import KanbanColumn from '../src/components/KanbanColumn.vue'
import TaskCard from '../src/components/TaskCard.vue'

const mockColumn = { id: 'todo', title: '待办', color: '#4a9eff' }
const mockTasks = [
  { id: '1', title: '任务1', columnId: 'todo', createdAt: Date.now() },
  { id: '2', title: '任务2', columnId: 'todo', createdAt: Date.now() }
]

describe('KanbanColumn 组件', () => {
  it('渲染列标题', () => {
    const wrapper = mount(KanbanColumn, {
      props: { column: mockColumn, taskList: mockTasks },
      global: { components: { TaskCard } }
    })
    expect(wrapper.text()).toContain('待办')
  })

  it('显示任务数量', () => {
    const wrapper = mount(KanbanColumn, {
      props: { column: mockColumn, taskList: mockTasks },
      global: { components: { TaskCard } }
    })
    expect(wrapper.text()).toContain('2')
  })

  it('空列显示提示文字', () => {
    const wrapper = mount(KanbanColumn, {
      props: { column: mockColumn, taskList: [] },
      global: { components: { TaskCard } }
    })
    expect(wrapper.text()).toContain('暂无任务')
    expect(wrapper.text()).toContain('点击上方按钮添加新任务')
  })

  it('drop 事件触发 move 事件', async () => {
    const wrapper = mount(KanbanColumn, {
      props: { column: mockColumn, taskList: [] },
      global: { components: { TaskCard } }
    })
    const dropEvent = {
      dataTransfer: { getData: () => 'task1', dropEffect: 'move' },
      preventDefault: vi.fn()
    }
    await wrapper.find('.kanban-column').trigger('drop', dropEvent)
    expect(wrapper.emitted('move')).toBeTruthy()
    expect(wrapper.emitted('move')[0]).toEqual(['task1', 'todo', 0])
  })
})
