import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { loadState, saveState, generateId, DEFAULT_COLUMNS, STORAGE_KEY } from '../src/utils/storage.js'

describe('storage 工具函数', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  describe('loadState', () => {
    it('无数据时返回默认状态', () => {
      const state = loadState()
      expect(state.columns).toEqual(DEFAULT_COLUMNS)
      expect(state.tasks).toEqual([])
    })

    it('有有效数据时返回已保存数据', () => {
      const saved = {
        columns: [{ id: 'custom', title: '自定义', color: '#000' }],
        tasks: [{ id: '1', title: '任务1', columnId: 'custom' }]
      }
      localStorage.setItem(STORAGE_KEY, JSON.stringify(saved))
      const state = loadState()
      expect(state.columns).toEqual(saved.columns)
      expect(state.tasks).toEqual(saved.tasks)
    })

    it('数据格式不正确时返回默认状态', () => {
      localStorage.setItem(STORAGE_KEY, '{invalid json')
      const state = loadState()
      expect(state.columns).toEqual(DEFAULT_COLUMNS)
      expect(state.tasks).toEqual([])
    })

    it('数据缺少必要字段时返回默认状态', () => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ columns: [] }))
      const state = loadState()
      expect(state.columns).toEqual(DEFAULT_COLUMNS)
    })
  })

  describe('saveState', () => {
    it('正确保存状态到 localStorage', () => {
      const state = { columns: DEFAULT_COLUMNS, tasks: [{ id: '1', title: '任务' }] }
      saveState(state)
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY))
      expect(saved).toEqual(state)
    })
  })

  describe('generateId', () => {
    it('生成唯一ID', () => {
      const ids = new Set()
      for (let i = 0; i < 100; i++) {
        ids.add(generateId())
      }
      expect(ids.size).toBe(100)
    })

    it('ID为字符串类型', () => {
      expect(typeof generateId()).toBe('string')
    })
  })
})
