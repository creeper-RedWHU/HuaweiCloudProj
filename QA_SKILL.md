---
name: qa
description: |
  任务管理看板 质量测试技能。对 http://119.3.174.235/ 执行全链路质量核验，
  涵盖功能验证、安全渗透、边界探索、异常恢复、性能评估、兼容性检测。
  触发词：测试、QA、质量、用例、回归、安全测试、测试报告。
---

# 任务管理看板 — 质量测试技能

你是资深 QA 工程师，负责对「任务管理看板」执行系统化质量测试并输出可追溯的测试证据。

## 被测系统

| 维度 | 详情 |
|------|------|
| URL | http://119.3.174.235/ |
| 标题 | 任务管理看板 |
| 架构 | Vue 3 SPA (Vite 构建)，纯前端无后端 |
| 存储 | localStorage，key=`task-kanban-data` |
| 路由 | 单页，无路由切换 |
| 认证 | 无，公开访问 |

## 功能全景

### 看板结构
- 三列：**待办** (todo) / **进行中** (doing) / **已完成** (done)
- 每列显示任务卡片列表 + 列标题 + 任务计数

### 任务实体
| 字段 | 类型 | 必填 | 长度限制 | 说明 |
|------|------|------|----------|------|
| id | string | 自动 | — | 唯一标识，程序生成 |
| title | string | 是 | maxlength=100 | 任务标题 |
| description | string | 否 | maxlength=500 | 任务描述，多行文本 |
| category | string | 否 | maxlength=20 | 自定义分类标签 |
| columnId | enum | 是 | — | todo / doing / done |
| starred | boolean | 否 | — | 星标标记 |
| urgent | boolean | 否 | — | 紧急标记 |
| createdAt | number | 自动 | — | Unix 时间戳 |

### 交互操作
1. **新增任务**: 模态框表单，标题必填（HTML5 required），其余选填
2. **删除任务**: 卡片 × 按钮，即时生效无确认
3. **星标切换**: 卡片 ★ 按钮，切换 `starred` 状态
4. **紧急切换**: 卡片 ! 按钮，切换 `urgent` 状态
5. **拖拽移动**: 卡片可在三列间拖拽，更新 `columnId`
6. **重置**: 清除全部数据，带 confirm 确认弹窗
7. **ESC 关闭**: 模态框支持 ESC 键关闭

### 数据流
```
用户操作 → Vue 响应式状态更新 → localStorage.setItem('task-kanban-data', JSON)
页面加载 → localStorage.getItem → JSON.parse → 初始化 Vue 状态 → 渲染
```

---

## 一、测试策略

### 测试金字塔

```
         /  Exploratory  \
        /   E2E (Playwright) \
       /   Integration        \
      /    Unit / Validation    \
```

- **Unit**: 输入验证逻辑 (maxlength, required, HTML5 constraint validation)
- **Integration**: localStorage 读写一致性、状态-UI 绑定
- **E2E**: 完整用户流程 (Playwright 自动化)
- **Exploratory**: 自由探索，发现非预期行为

### 测试维度权重

| 维度 | 权重 | 理由 |
|------|------|------|
| 功能正确性 | 40% | 核心价值 |
| 数据完整性 | 20% | localStorage 是唯一数据源 |
| 输入安全性 | 15% | 公开访问，XSS 面大 |
| 边界容错 | 15% | 纯前端，异常输入不能崩溃 |
| 兼容性 | 10% | 多浏览器/视口 |

---

## 二、测试用例设计

### 设计原则
1. **可复现**: 每个用例包含前置条件、步骤、预期结果
2. **独立性**: 用例间不依赖执行顺序
3. **可自动化**: 优先设计可通过 Playwright 执行的用例
4. **优先级标记**: P0 阻塞 / P1 严重 / P2 一般 / P3 建议

### 用例模板

每条用例遵循：

```
## TC-{模块}-{编号} | {标题}
- 优先级: P0/P1/P2/P3
- 类型: 功能/安全/边界/异常/性能/兼容性
- 前置: {初始状态}
- 步骤:
  1. {操作}
  2. {操作}
- 预期: {可验证的预期结果}
- 实际: (执行后填写)
- 状态: ✅通过 / ❌失败 / ⚠️跳过
```

### 功能测试矩阵

| 编号 | 测试点 | 优先级 | 自动化 |
|------|--------|--------|--------|
| F-01 | 页面加载，三列看板渲染正确 | P0 | 是 |
| F-02 | 新增任务 — 仅必填字段 | P0 | 是 |
| F-03 | 新增任务 — 全部字段填写 | P0 | 是 |
| F-04 | 新增任务 — 各状态列 (todo/doing/done) | P0 | 是 |
| F-05 | 新增任务 — 星标/紧急设置 | P1 | 是 |
| F-06 | 新增任务 — 自定义分类 | P2 | 是 |
| F-07 | 取消新增，任务不残留 | P1 | 是 |
| F-08 | 删除任务 — 单条 | P0 | 是 |
| F-09 | 删除任务 — 清空全部后状态 | P2 | 是 |
| F-10 | 星标切换 — 启用/取消 | P1 | 是 |
| F-11 | 紧急切换 — 启用/取消 | P1 | 是 |
| F-12 | 拖拽 — todo → doing | P0 | 是 |
| F-13 | 拖拽 — doing → done | P0 | 是 |
| F-14 | 拖拽 — done → todo (回退) | P1 | 是 |
| F-15 | 重置 — confirm 确认 | P1 | 是 |
| F-16 | 重置 — confirm 取消 | P2 | 是 |
| F-17 | 任务计数 — 总数正确 | P1 | 是 |
| F-18 | 任务计数 — 各列独立计数 | P1 | 是 |
| F-19 | localStorage 持久化 — 刷新不丢数据 | P0 | 是 |
| F-20 | localStorage 数据结构校验 | P1 | 是 |
| F-21 | 模态框 — ESC 关闭 | P2 | 是 |
| F-22 | 模态框 — 点击遮罩关闭 (如适用) | P3 | 是 |
| F-23 | 批量添加 50+ 任务 | P2 | 是 |

### 安全测试矩阵

| 编号 | 测试点 | 向量 | 优先级 |
|------|--------|------|--------|
| S-01 | XSS — 标题注入 script 标签 | `<script>alert(1)</script>` | P0 |
| S-02 | XSS — 标题注入 img onerror | `<img src=x onerror=alert(1)>` | P0 |
| S-03 | XSS — 标题注入事件处理器 | `<div onmouseover=alert(1)>` | P0 |
| S-04 | XSS — 描述字段注入 | `<script>alert(1)</script>` | P0 |
| S-05 | XSS — 分类字段注入 | `<img src=x onerror=alert(1)>` | P0 |
| S-06 | XSS — iframe 注入 | `<iframe src="javascript:alert(1)">` | P1 |
| S-07 | XSS — svg onload | `<svg onload=alert(1)>` | P1 |
| S-08 | XSS — URL 编码绕过 | `%3Cscript%3Ealert(1)%3C/script%3E` | P1 |
| S-09 | XSS — 大小写绕过 | `<ScRiPt>alert(1)</sCrIpT>` | P1 |
| S-10 | XSS — 换行绕过 | `<script>\nalert(1)\n</script>` | P2 |
| S-11 | XSS — Unicode 同形字 | `<scrıpt>` (dotless i) | P2 |
| S-12 | localStorage — XSS 持久化注入 | 直接写 localStorage | P0 |
| S-13 | localStorage — 损坏 JSON 恢复 | 写入非法 JSON | P1 |
| S-14 | localStorage — 无效 columnId | 写入无效应列 ID | P1 |
| S-15 | localStorage — 缺少字段 | 写入不完整任务对象 | P2 |
| S-16 | localStorage — 敏感信息检查 | 搜索 password/token/key | P1 |
| S-17 | HTTP — 安全响应头检查 | 检查 CSP/X-Frame-Options 等 | P2 |
| S-18 | HTML 实体编码绕过 | `&lt;script&gt;` | P2 |
| S-19 | 批量 XSS 向量扫描 | 14+ 常见向量 | P1 |
| S-20 | 超大字符串渲染不崩溃 | title/desc 各 10000 字符 | P1 |

### 边界与异常测试矩阵

| 编号 | 测试点 | 优先级 |
|------|--------|--------|
| B-01 | 标题 — 最大长度 100 字符 | P1 |
| B-02 | 标题 — maxlength 属性校验 | P1 |
| B-03 | 标题 — 最小长度 1 字符 | P1 |
| B-04 | 标题 — 空字符串必填拦截 | P0 |
| B-05 | 标题 — 纯空格处理 | P1 |
| B-06 | 标题 — HTML 标签转义 | P1 |
| B-07 | 标题 — 特殊字符 !@#$%^&*() | P2 |
| B-08 | 标题 — Emoji 😀🔥🎉 | P2 |
| B-09 | 标题 — 中英日韩混合 | P2 |
| B-10 | 描述 — 最大长度 500 字符 | P1 |
| B-11 | 描述 — maxlength 属性校验 | P1 |
| B-12 | 描述 — 空值 (可选字段) | P1 |
| B-13 | 描述 — 换行符 \n | P2 |
| B-14 | 分类 — 最大长度 20 字符 | P2 |
| B-15 | 分类 — maxlength 属性校验 | P2 |
| B-16 | 分类 — 空值 (可选字段) | P2 |
| B-17 | 离线操作 | P2 |
| B-18 | localStorage 被清空后刷新 | P1 |
| B-19 | 快速连续点击新增按钮 | P2 |
| B-20 | 快速连续点击添加按钮 (防重复提交) | P1 |
| B-21 | 移动端视口 375×812 | P2 |
| B-22 | localStorage 首次使用 (无 key) | P1 |

---

## 三、自动化测试

### 技术栈
- **Playwright** v1.60+ (Chromium)
- Node.js ESM

### 配置文件 (`playwright.config.js`)

```js
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  expect: { timeout: 10000 },
  use: {
    baseURL: 'http://119.3.174.235',
    locale: 'zh-CN',
    screenshot: 'on',
    video: 'off',
    trace: 'off',
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['json', { outputFile: 'test-results.json' }],
  ],
});
```

### 执行命令

```bash
# 全部测试
npx playwright test

# 按类型筛选
npx playwright test --grep "TC-F"     # 功能测试
npx playwright test --grep "TC-S"     # 安全测试
npx playwright test --grep "TC-B|TC-E" # 边界异常

# 调试
npx playwright test --ui              # 交互式 UI 模式
npx playwright test --debug           # 单步调试
PWDEBUG=1 npx playwright test         # Playwright Inspector

# 报告
npx playwright show-report            # 查看 HTML 报告
```

### 测试文件结构

```
tests/
├── functional.spec.js   # 功能正确性测试
├── security.spec.js     # XSS / 数据安全测试
└── boundary.spec.js     # 边界值 / 异常恢复测试
```

### 通用测试夹具 (beforeEach)

每个测试用例前必须清空 localStorage 并刷新，确保隔离：

```js
test.beforeEach(async ({ page }) => {
  await page.goto('http://119.3.174.235', { waitUntil: 'networkidle' });
  await page.evaluate(() => localStorage.clear());
  await page.reload({ waitUntil: 'networkidle' });
});
```

### XSS 测试规范

所有 XSS 测试必须：
1. 注册 `page.on('dialog', handler)` 监听弹窗
2. 注入后验证 `dialogAppeared === false`
3. 优先通过 UI 输入注入（模拟真实攻击路径）
4. 补充 localStorage 直接注入（模拟存储型 XSS）

### 直接 localStorage 注入辅助函数

```js
async function injectViaStorage(page, taskOverrides = {}) {
  await page.evaluate((overrides) => {
    const data = {
      columns: [
        { id: 'todo', title: '待办', color: '#4a9eff' },
        { id: 'doing', title: '进行中', color: '#f5a623' },
        { id: 'done', title: '已完成', color: '#7ed321' }
      ],
      tasks: [{
        id: 'injected-' + Date.now(),
        title: 'default',
        description: '',
        category: '',
        columnId: 'todo',
        starred: false,
        urgent: false,
        createdAt: Date.now(),
        ...overrides
      }]
    };
    localStorage.setItem('task-kanban-data', JSON.stringify(data));
  }, taskOverrides);
  await page.reload({ waitUntil: 'networkidle' });
}
```

---

## 四、测试执行流程

### 完整测试流程

```
1. 环境准备
   ├── 确认 Node.js 环境
   ├── npm install
   └── npx playwright install chromium

2. 探索性测试 (手动)
   ├── 打开 http://119.3.174.235/
   ├── 遍历全部交互操作
   ├── 记录 UI 截图
   └── 发现非预期行为

3. 自动化测试执行
   ├── npx playwright test (全量)
   ├── 截图自动保存至 test-results/
   └── 生成 JSON + HTML 报告

4. 安全测试专项
   ├── XSS 向量逐个验证
   ├── localStorage 篡改测试
   └── 安全响应头检查

5. 报告输出
   ├── 汇总通过/失败/跳过
   ├── 缺陷描述 + 截图证据
   ├── 风险评估与建议
   └── 输出 test-report-{系统}-{日期}.md
```

### 缺陷分级

| 级别 | 定义 | 示例 |
|------|------|------|
| P0 致命 | 核心功能不可用或数据丢失 | 添加任务失败、刷新后数据丢失 |
| P1 严重 | 主要功能异常或安全隐患 | XSS 执行、输入校验缺失 |
| P2 一般 | 次要功能异常或体验问题 | 视觉瑕疵、边界处理不当 |
| P3 建议 | 优化建议 | 缺少安全响应头、文案优化 |

---

## 五、测试报告模板

```markdown
# 测试报告 — {系统名称}

**测试日期**: YYYY-MM-DD
**测试环境**: {浏览器/版本/视口}
**测试人员**: AI QA Agent

---

## 一、测试概述

| 指标 | 数值 |
|------|------|
| 测试用例总数 | N |
| 通过 | N |
| 失败 | N |
| 跳过 | N |
| 通过率 | XX% |

## 二、缺陷统计

| 级别 | 数量 | 状态 |
|------|------|------|
| P0 致命 | N | — |
| P1 严重 | N | — |
| P2 一般 | N | — |
| P3 建议 | N | — |

## 三、缺陷详情

### BUG-001 | {标题}
- **级别**: P0/P1/P2/P3
- **模块**: {功能模块}
- **步骤**: 
  1. ...
  2. ...
- **预期**: ...
- **实际**: ...
- **截图**: ![](path)

## 四、安全测试结果

| 检查项 | 状态 |
|--------|------|
| XSS 注入防护 | ✅/❌ |
| localStorage 数据完整性 | ✅/❌ |
| 输入验证 | ✅/❌ |
| 安全响应头 | ✅/❌ |

## 五、测试结论

{整体评估、风险提示、上线建议}
```

---

## 六、环境搭建指南

### 一键安装

```bash
cd QA_skill
npm install
npx playwright install chromium
```

### 验证安装

```bash
npx playwright --version
node -e "console.log('Node:', process.version)"
```

### 手动运行单个测试文件

```bash
npx playwright test tests/functional.spec.js
npx playwright test tests/security.spec.js
npx playwright test tests/boundary.spec.js
```

---

## 七、交付件

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 本技能定义 |
| `tests/functional.spec.js` | 功能测试自动化脚本 |
| `tests/security.spec.js` | 安全测试自动化脚本 |
| `tests/boundary.spec.js` | 边界值与异常测试脚本 |
| `test-report-{系统}-{日期}.md` | 测试执行报告 |
| `screenshots/` | 测试截图 |
| `playwright-report/` | Playwright HTML 报告 |
| `test-results.json` | 机器可读测试结果 |

---

## 八、AI Agent 行为指南

当用户触发此 Skill 时，Agent 应：

1. **首次使用**: 检查环境 → 执行探索 → 设计用例 → 运行测试 → 输出报告
2. **增量测试**: 只运行相关 spec 文件，对比上次结果
3. **修复验证**: 针对特定缺陷运行对应用例，确认修复
4. **回归测试**: 全量运行，比对基线报告
5. **只输出报告**: 仅基于已有测试结果生成报告，不重新执行

### 错误处理

- 如果 Playwright 未安装 → 输出安装命令让用户手动执行
- 如果测试全部失败 → 检查 APP_URL 是否可达，截图确认页面状态
- 如果个别用例失败 → 分析失败原因，区分环境问题 vs 应用缺陷
- 如果截图目录不存在 → 自动创建
