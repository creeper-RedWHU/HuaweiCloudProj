import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import AddTaskModal from '../src/components/AddTaskModal.vue'
import { DEFAULT_COLUMNS } from '../src/utils/storage.js'

describe('AddTaskModal 组件', () => {
  it('渲染表单元素', () => {
    const wrapper = mount(AddTaskModal, {
      props: { columns: DEFAULT_COLUMNS, existingCategories: [] }
    })
    expect(wrapper.find('input[type="text"]').exists()).toBe(true)
    expect(wrapper.find('textarea').exists()).toBe(true)
    expect(wrapper.find('select').exists()).toBe(true)
  })

  it('空标题提交无反应', async () => {
    const wrapper = mount(AddTaskModal, {
      props: { columns: DEFAULT_COLUMNS, existingCategories: [] }
    })
    await wrapper.find('form').trigger('submit.prevent')
    expect(wrapper.emitted('submit')).toBeFalsy()
  })

  it('填写标题后提交触发 submit 事件', async () => {
    const wrapper = mount(AddTaskModal, {
      props: { columns: DEFAULT_COLUMNS, existingCategories: [] }
    })
    await wrapper.find('input[type="text"]').setValue('新任务')
    await wrapper.find('form').trigger('submit.prevent')
    expect(wrapper.emitted('submit')).toBeTruthy()
    const submittedTask = wrapper.emitted('submit')[0][0]
    expect(submittedTask.title).toBe('新任务')
    expect(submittedTask.id).toBeTruthy()
    expect(submittedTask.createdAt).toBeTruthy()
  })

  it('点击取消触发 close 事件', async () => {
    const wrapper = mount(AddTaskModal, {
      props: { columns: DEFAULT_COLUMNS, existingCategories: [] }
    })
    await wrapper.find('.btn-cancel').trigger('click')
    expect(wrapper.emitted('close')).toBeTruthy()
  })

  it('显示已有分类的 datalist', () => {
    const wrapper = mount(AddTaskModal, {
      props: { columns: DEFAULT_COLUMNS, existingCategories: ['设计', '开发'] }
    })
    const options = wrapper.findAll('datalist option')
    expect(options.length).toBe(2)
  })
})
