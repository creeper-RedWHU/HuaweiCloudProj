# 任务管理看板 - 项目总览

## 一、项目定位

基于 Vue 3 的看板任务管理应用，支持拖拽、主题切换、数据持久化，自动 CI/CD 部署到华为云 ECS。

---

## 二、技术栈

| 维度 | 技术 | 版本 |
|------|------|------|
| 框架 | Vue 3 (Composition API + `<script setup>`) | ^3.3.0 |
| 构建 | Vite | ^4.5.0 |
| 测试 | Vitest + @vue/test-utils + jsdom | ^0.34.0 |
| 样式 | 原生 CSS + CSS 变量（无预处理器） | - |
| 类型 | TypeScript（部分文件） | - |
| IaC | Terraform + 华为云 Provider | 1.9.8 / 1.90.0 |
| CI/CD | GitHub Actions | - |

---

## 三、目录结构

```
HuaweiCloudProj/
├── src/
│   ├── main.js                         # 入口
│   ├── App.vue                         # 根组件
│   ├── components/                     # UI 组件
│   │   ├── NavBar.vue                  # 导航栏（统计+按钮+主题）
│   │   ├── KanbanColumn.vue            # 看板列（拖拽目标）
│   │   ├── TaskCard.vue                # 任务卡片（拖拽源）
│   │   ├── AddTaskModal.vue            # 新增任务弹窗
│   │   ├── FunToast.vue                # Toast 通知
│   │   └── ThemeSelector.vue           # 主题选择器
│   ├── composables/                    # 组合式函数
│   │   ├── useKanban.js               # 看板数据管理
│   │   ├── useTheme.ts                # 主题管理
│   │   └── useToast.ts                # Toast 管理
│   ├── config/                         # 配置
│   │   ├── themes.ts                  # 主题定义（亮/暗/多彩）
│   │   └── toastMessages.ts           # Toast 消息库
│   ├── styles/
│   │   └── variables.css              # CSS 变量（设计令牌）
│   ├── utils/                          # 工具
│   │   ├── storage.js                 # localStorage 持久化
│   │   ├── cssVariables.ts            # CSS 变量动态操作
│   │   └── timeFormat.ts             # 时间格式化
│   └── assets/
│       └── main.css                   # 全局样式+动画+响应式
├── tests/                              # 单元测试
├── terraform/                          # 基础设施即代码
├── .github/workflows/ci-cd.yml        # CI/CD 工作流
└── docs/                               # 文档
```

---

## 四、组件架构图

```
┌─────────────────────────────────────────────────┐
│                    App.vue                       │
│  状态: showModal, previousColumnMap              │
│  组合: useKanban(), useToast()                   │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────── NavBar.vue ────────────┐         │
│  │ 统计(总计/待办/进行中/已完成)       │         │
│  │ [+新增] [↻重置]                    │         │
│  │  ┌─ ThemeSelector.vue ─┐          │         │
│  │  │ 亮色 | 暗色 | 多彩  │          │         │
│  │  └─────────────────────┘          │         │
│  └────────────────────────────────────┘         │
│                                                  │
│  ┌─ KanbanColumn ─┐ ┌─ KanbanColumn ─┐ ┌─ ... ─┐│
│  │    待办         │ │    进行中       │ │ 已完成 ││
│  │ ┌─────────────┐ │ │ ┌─────────────┐│ │        ││
│  │ │  TaskCard   │ │ │ │  TaskCard   ││ │        ││
│  │ │ 拖拽/星标/  │ │ │ │ 紧急/删除   ││ │        ││
│  │ └─────────────┘ │ │ └─────────────┘│ │        ││
│  └─────────────────┘ └─────────────────┘ └────────┘│
│                                                  │
│  ┌─ AddTaskModal.vue ──┐   ┌─ FunToast.vue ──┐  │
│  │ 标题/描述/分类/列   │   │  通知+进度条    │  │
│  │ 星标/紧急 复选框    │   │  悬停暂停      │  │
│  └───────────────────────┘   └─────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 五、数据流图

```
┌──────────────────────────────────────────────────────────┐
│                    localStorage                          │
│  key: task-kanban-data → { columns, tasks }             │
│  key: task-kanban-theme → themeId                       │
└──────────┬───────────────────────────────┬──────────────┘
           │ load                          │ load
           ▼                               ▼
┌─────────────────────┐        ┌─────────────────────┐
│    useKanban()      │        │    useTheme()       │
│  ┌───────────────┐  │        │  ┌───────────────┐  │
│  │ columns: ref  │  │        │  │currentTheme:  │  │
│  │ tasks: ref    │  │       │  │    ref         │  │
│  └───────┬───────┘  │        │  └───────┬───────┘  │
│          │ watch    │        │          │ setTheme  │
│          ▼          │        │          ▼           │
│     saveState()     │        │  applyTheme()       │
│     → localStorage  │        │  → CSS变量更新      │
└──────────┬──────────┘        └──────────┬──────────┘
           │                              │
           │ 提供                          │ 提供
           ▼                              ▼
┌──────────────────────────────────────────────────────┐
│                     App.vue                           │
│  addTask / removeTask / moveTask / toggleTaskFlag    │
│  resetBoard / getTasksByColumn                       │
└──────────────────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────┐
│  useToast()  ←──  toastMessages.ts                   │
│  show(type) / success() / error() / remove()         │
│           │                                           │
│           ▼                                           │
│  ┌── FunToast.vue ──┐                                │
│  │ 消息 + 进度条     │                                │
│  └────────────────────┘                                │
└──────────────────────────────────────────────────────┘
```

---

## 六、核心功能模块

### 6.1 拖拽系统

```
TaskCard (draggable=true)          KanbanColumn (drop target)
     │                                    │
     │ dragstart                          │ dragover
     │ → dataTransfer.setData(taskId)     │ → 高亮效果
     │                                    │
     │ ────── 拖动到目标列 ──────►       │ drop
     │                                    │ → emit('move', taskId, columnId)
     │                                    │
     ▼                                    ▼
  App.vue → moveTask(taskId, toColumnId)
           → 更新 task.columnId
           → watch 触发 Toast 通知
```

### 6.2 主题系统

```
themes.ts                    useTheme.ts               document.documentElement
┌─────────────┐            ┌─────────────┐           ┌─────────────────────┐
│ lightTheme  │ ──setTheme→│ currentTheme│ ──apply──→│ --color-primary    │
│ darkTheme   │ ──preview─→│ previewTheme│ ──apply──→│ --color-background │
│ colorfulTheme│ ──stop───→│             │ ──restore→│ --color-surface    │
└─────────────┘            └─────────────┘           └─────────────────────┘
```

### 6.3 持久化方案

```
useKanban()                      storage.js                   localStorage
┌──────────────┐                ┌──────────────┐             ┌──────────┐
│ columns: ref │ ──watch(deep)→│ saveState()  │ ──setItem──→│ kanban-  │
│ tasks: ref   │                │              │             │ data     │
└──────────────┘                │ loadState()  │ ←─getItem──←│          │
       ▲                        └──────────────┘             └──────────┘
       │ init                         
       └── loadState() → 恢复或使用默认值
```

---

## 七、CI/CD 部署架构图

```
┌──────────┐     push      ┌──────────────────┐     CI通过     ┌──────────────────┐
│  开发者   │ ───────────→ │   GitHub Repo    │ ───────────→ │  GitHub Actions   │
│           │               │   (main分支)     │              │    Runner         │
└──────────┘               └──────────────────┘              └────────┬─────────┘
                                                                      │
                                    ┌─────────────────────────────────┤
                                    │                                 │
                              CI Job                              Deploy Job
                                    │                                 │
                        ┌───────────▼───────────┐         ┌─────────▼──────────┐
                        │ 1. checkout           │         │ 1. download artifact│
                        │ 2. setup-node (cache) │         │ 2. SSH: 备份+清空  │
                        │ 3. npm ci             │         │ 3. SCP: 上传dist   │
                        │ 4. lint               │         │ 4. SSH: reload验证 │
                        │ 5. test               │         │ 5. 健康检查/回滚   │
                        │ 6. build              │         └─────────┬──────────┘
                        │ 7. upload artifact    │                   │
                        └───────────────────────┘                   │
                                                              SSH + SCP
                                                                    │
                                                                    ▼
                                                        ┌──────────────────┐
                                                        │   华为云 ECS      │
                                                        │  119.3.174.235   │
                                                        │                  │
                                                        │ /var/www/        │
                                                        │  task-kanban/    │
                                                        │   ├── dist/      │
                                                        │   ├── backups/   │
                                                        │   └── .version   │
                                                        │                  │
                                                        │  Nginx :80 → dist│
                                                        └────────┬─────────┘
                                                                 │
                                                                 ▼
                                                           用户访问
                                                        http://119.3.174.235
```

---

## 八、基础设施架构图

```
┌─────────────────────────────────────────────────────────┐
│                    华为云 cn-north-4                     │
│                                                         │
│  ┌──────────── VPC ────────────┐                       │
│  │  task-kanban-vpc            │                       │
│  │  192.168.0.0/16             │                       │
│  │                              │                       │
│  │  ┌─── Subnet ────────────┐  │                       │
│  │  │ task-kanban-subnet    │  │                       │
│  │  │ 192.168.1.0/24       │  │                       │
│  │  │                       │  │                       │
│  │  │  ┌─── ECS ─────────┐ │  │     ┌── EIP ──────┐  │
│  │  │  │ task-kanban-ecs │ │  │     │ 119.3.174.235│  │
│  │  │  │ s6.large.2      │◄┼──┼─────┤ 5Mbps BGP   │  │
│  │  │  │ Ubuntu 22.04    │ │  │     └─────────────┘  │
│  │  │  │ 40GB+40GB GPSSD│ │  │                       │
│  │  │  └────────────────┘ │  │                       │
│  │  └──────────────────────┘  │                       │
│  └─────────────────────────────┘                       │
│                                                         │
│  ┌─── Security Group ──────────────────────────────┐   │
│  │ task-kanban-sg                                  │   │
│  │ Ingress: TCP 22(SSH) 80(HTTP) 443(HTTPS)       │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 九、事件流全景图

```
用户操作              组件事件              数据操作              副作用
─────────────────────────────────────────────────────────────────────
点击[新增]     → NavBar emit('add-task')
              → App: showModal=true
              → AddTaskModal 渲染

提交表单       → Modal emit('submit', task)
              → App: addTask(task)
              → useKanban: tasks.push(task)
              → watch → saveState()        → localStorage写入
              → showToast('taskAdd')        → FunToast 显示

拖拽卡片       → Column emit('move', id, col)
              → App: moveTask(id, colId)
              → useKanban: task.columnId=colId
              → watch → saveState()        → localStorage写入
              → watch → showToast()        → FunToast 显示

星标/紧急      → Card emit('toggle', id, flag)
              → App: toggleTaskFlag(id, flag)
              → useKanban: task[flag]=!task[flag]
              → watch → saveState()        → localStorage写入

删除任务       → Card emit('remove', id)
              → App: removeTask(id)
              → useKanban: tasks.filter()
              → watch → saveState()        → localStorage写入
              → showToast('taskDelete')     → FunToast 显示

重置看板       → NavBar emit('reset')
              → App: resetBoard()
              → useKanban: 恢复默认
              → watch → saveState()        → localStorage写入
              → showToast('reset')         → FunToast 显示

切换主题       → ThemeSelector.setTheme(id)
              → useTheme: currentTheme=theme
              → applyTheme()               → CSS变量更新
              → localStorage写入           → theme持久化
```

---

## 十、设计特点

| 特点 | 说明 |
|------|------|
| 无路由/无状态库 | 纯 SPA 单页，composables 替代 Pinia/Vuex |
| 模块级单例 | useToast/useTheme 在模块顶层定义 ref，全局共享 |
| HTML5 原生拖拽 | 无第三方拖拽库，dragstart/drop/dataTransfer |
| CSS 变量主题 | 运行时动态修改 document.documentElement，无需重新构建 |
| 全自动部署 | push → CI(检查+测试+构建) → CD(备份+上传+验证+回滚) |
| 按需计费 | ECS 按需付费，¥0.32/小时，不用不花钱 |
