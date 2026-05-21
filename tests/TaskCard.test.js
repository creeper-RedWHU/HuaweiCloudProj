import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import TaskCard from '../src/components/TaskCard.vue'

const mockTask = {
  id: 'task1',
  title: '测试任务',
  description: '任务描述',
  category: '开发',
  columnId: 'todo',
  starred: false,
  urgent: false,
  createdAt: Date.now()
}

describe('TaskCard 组件', () => {
  it('渲染任务标题', () => {
    const wrapper = mount(TaskCard, { props: { task: mockTask } })
    expect(wrapper.text()).toContain('测试任务')
  })

  it('渲染任务描述', () => {
    const wrapper = mount(TaskCard, { props: { task: mockTask } })
    expect(wrapper.text()).toContain('任务描述')
  })

  it('渲染分类标签', () => {
    const wrapper = mount(TaskCard, { props: { task: mockTask } })
    expect(wrapper.text()).toContain('开发')
  })

  it('无描述时不显示描述区域', () => {
    const task = { ...mockTask, description: '' }
    const wrapper = mount(TaskCard, { props: { task } })
    expect(wrapper.find('.card-desc').exists()).toBe(false)
  })

  it('星标任务应用 is-starred 类', () => {
    const task = { ...mockTask, starred: true }
    const wrapper = mount(TaskCard, { props: { task } })
    expect(wrapper.find('.task-card').classes()).toContain('is-starred')
  })

  it('紧急任务应用 is-urgent 类', () => {
    const task = { ...mockTask, urgent: true }
    const wrapper = mount(TaskCard, { props: { task } })
    expect(wrapper.find('.task-card').classes()).toContain('is-urgent')
  })

  it('点击删除按钮触发 remove 事件', () => {
    const wrapper = mount(TaskCard, { props: { task: mockTask } })
    wrapper.find('.btn-delete').trigger('click')
    expect(wrapper.emitted('remove')).toBeTruthy()
    expect(wrapper.emitted('remove')[0]).toEqual([mockTask.id])
  })

  it('点击星标按钮触发 toggle 事件', () => {
    const wrapper = mount(TaskCard, { props: { task: mockTask } })
    const starBtn = wrapper.findAll('.btn-icon')[0]
    starBtn.trigger('click')
    expect(wrapper.emitted('toggle')).toBeTruthy()
    expect(wrapper.emitted('toggle')[0]).toEqual([mockTask.id, 'starred'])
  })

  it('可拖拽', () => {
    const wrapper = mount(TaskCard, { props: { task: mockTask } })
    expect(wrapper.find('.task-card').attributes('draggable')).toBe('true')
  })
})
