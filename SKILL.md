---
name: task-kanban
description: 任务管理看板 - Vue3 + Vite + localStorage 纯前端项目，涵盖产品PRD、组件化开发、功能测试全流程
triggers:
  - 任务看板
  - 看板
  - kanban
  - 任务管理
---

# 任务管理看板 Skill

## 一、项目概述

任务管理看板是一个纯前端项目，使用 **Vue3 + Vite + localStorage** 实现。完整走完产品→开发→测试全流程，重点锻炼 Vue 组件化思想和前端数据持久化。

## 二、产品视角 — 用户故事与 PRD

### 2.1 用户故事

| 编号 | 用户故事 | 验收标准 |
|------|---------|---------|
| US-01 | 作为用户，我想新增任务，以便记录待办事项 | 点击"新增任务"弹出表单，填写标题/描述/分类/状态后保存 |
| US-02 | 作为用户，我想拖拽任务到不同列，以便调整任务状态 | 拖拽卡片到目标列，任务自动归入该列 |
| US-03 | 作为用户，我想给任务加星标，以便标记重要任务 | 点击星标按钮切换星标状态，卡片视觉区分 |
| US-04 | 作为用户，我想标记紧急任务，以便快速识别 | 点击紧急按钮切换紧急状态，卡片红色边框 |
| US-05 | 作为用户，我想按分类管理任务，以便按类别筛选 | 新增时可选分类，卡片显示分类标签 |
| US-06 | 作为用户，我想删除任务，以便移除不需要的项 | 点击删除按钮移除任务，数据同步更新 |
| US-07 | 作为用户，我想数据持久化，以便刷新后不丢失 | 所有操作自动保存至 localStorage，刷新后恢复 |
| US-08 | 作为用户，我想重置看板，以便清空重新开始 | 点击重置按钮，确认后清空所有任务 |

### 2.2 任务流转逻辑

```
新增任务 ──→ [待办] ──拖拽──→ [进行中] ──拖拽──→ [已完成]
   │                                              │
   └──────── 任意列之间可双向拖拽 ────────────────┘
```

- 三列状态：待办(todo) → 进行中(doing) → 已完成(done)
- 拖拽可在任意列之间双向流转
- 每列显示任务计数
- 空列显示拖拽提示

## 三、开发视角 — 组件架构

### 3.1 组件树

```
App.vue
├── KanbanColumn.vue (×3)
│   └── TaskCard.vue (×N)
└── AddTaskModal.vue (条件渲染)
```

### 3.2 核心组件说明

| 组件 | 职责 | Props | Events |
|------|------|-------|--------|
| `TaskCard` | 单个任务卡片，支持拖拽、标记、删除 | `task` | `toggle(id, flag)`, `remove(id)` |
| `KanbanColumn` | 看板列容器，处理拖放 | `column`, `taskList` | `move(taskId, colId, index)`, `toggle`, `remove` |
| `AddTaskModal` | 新增任务弹窗表单 | `columns`, `existingCategories` | `submit(task)`, `close` |

### 3.3 Composable

- `useKanban()` — 核心状态管理
  - `columns` / `tasks` — 响应式数据
  - `addTask(task)` / `removeTask(id)` / `updateTask(id, updates)`
  - `toggleTaskFlag(id, flag)` — 切换星标/紧急
  - `moveTask(id, toCol, index)` — 拖拽移动
  - `getTasksByColumn(colId)` — 按列筛选
  - `resetBoard()` — 重置看板

### 3.4 工具函数

- `loadState()` / `saveState()` — localStorage 读写
- `generateId()` — 唯一 ID 生成
- `DEFAULT_COLUMNS` — 默认三列配置

### 3.5 数据模型

```typescript
interface Task {
  id: string
  title: string
  description?: string
  category?: string
  columnId: 'todo' | 'doing' | 'done'
  starred: boolean
  urgent: boolean
  createdAt: number
}

interface Column {
  id: string
  title: string
  color: string
}
```

## 四、测试视角 — 测试用例

### 4.1 功能测试用例

| 用例ID | 测试项 | 前置条件 | 操作步骤 | 预期结果 |
|--------|--------|---------|---------|---------|
| TC-01 | 新增任务 | 看板为空 | 点击新增→填标题→提交 | 待办列出现新卡片 |
| TC-02 | 新增空标题 | 弹窗打开 | 不填标题→提交 | 不提交，表单不关闭 |
| TC-03 | 删除任务 | 存在任务 | 点击卡片删除按钮 | 卡片移除，计数更新 |
| TC-04 | 星标切换 | 存在任务 | 点击星标按钮 | 星标状态切换，样式变化 |
| TC-05 | 紧急切换 | 存在任务 | 点击紧急按钮 | 紧急状态切换，样式变化 |
| TC-06 | 拖拽移动 | 多列有任务 | 拖卡片到另一列 | 卡片移至目标列 |
| TC-07 | 数据持久化 | 有任务数据 | 刷新页面 | 数据恢复，状态不变 |
| TC-08 | 重置看板 | 有任务数据 | 点重置→确认 | 所有任务清除 |
| TC-09 | localStorage 格式错误 | 手动写入错误数据 | 刷新页面 | 降级为默认状态 |
| TC-10 | 分类自动补全 | 已有"开发"分类 | 新增任务输入分类 | 出现已有分类建议 |

### 4.2 单元测试覆盖

- `storage.test.js` — localStorage 读写、ID 生成
- `TaskCard.test.js` — 渲染、标记、删除、拖拽
- `KanbanColumn.test.js` — 列渲染、计数、拖放
- `AddTaskModal.test.js` — 表单验证、提交、取消

## 五、项目结构

```
task-kanban/
├── index.html
├── package.json
├── vite.config.js
├── vitest.config.js
├── public/
├── src/
│   ├── main.js
│   ├── App.vue
│   ├── assets/
│   │   └── main.css
│   ├── components/
│   │   ├── TaskCard.vue
│   │   ├── KanbanColumn.vue
│   │   └── AddTaskModal.vue
│   ├── composables/
│   │   └── useKanban.js
│   └── utils/
│       └── storage.js
└── tests/
    ├── storage.test.js
    ├── TaskCard.test.js
    ├── KanbanColumn.test.js
    └── AddTaskModal.test.js
```

## 六、开发指南

### 6.1 启动项目

```bash
cd task-kanban
npm install
npm run dev
```

### 6.2 运行测试

```bash
npm test          # 单次运行
npm run test:watch # 监听模式
```

### 6.3 构建产物

```bash
npm run build
npm run preview
```

## 七、拓展方向

1. **拖拽排序** — 列内卡片排序（HTML5 DnD 或集成 sortablejs）
2. **多看板** — 支持创建/切换多个看板
3. **筛选过滤** — 按分类/星标/紧急筛选任务
4. **搜索功能** — 关键词搜索任务
5. **过期提醒** — 添加截止日期，过期任务高亮
6. **导入导出** — JSON 文件导入导出数据
7. **暗色模式** — 切换深色主题
