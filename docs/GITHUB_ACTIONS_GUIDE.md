# GitHub Actions CI/CD 配置指南

## 📋 前置要求

1. 项目已推送到GitHub仓库
2. 拥有GitHub仓库的管理员权限
3. 华为云ECS已部署且可访问

---

## 🔐 配置GitHub Secrets

### 步骤1: 进入仓库设置

1. 打开GitHub仓库页面
2. 点击 **Settings** 标签
3. 在左侧菜单找到 **Secrets and variables** → **Actions**
4. 点击 **New repository secret**

### 步骤2: 添加必需的Secrets

需要配置以下3个Secrets：

#### **ECS_HOST** (必需)

```
Name: ECS_HOST
Value: 119.3.174.235
```

**说明**: 华为云ECS的公网IP地址

---

#### **ECS_USER** (必需)

```
Name: ECS_USER
Value: root
```

**说明**: ECS的SSH登录用户名

---

#### **ECS_PASSWORD** (必需)

```
Name: ECS_PASSWORD
Value: whlRSK7.
```

**说明**: ECS的SSH登录密码

**⚠️ 安全提示**:
- 此密码仅用于示例，生产环境建议使用SSH密钥认证
- 密码存储在GitHub Secrets中，加密且不显示在日志中
- 建议定期更换密码

---

## 📊 Secrets配置检查清单

配置完成后，确认以下Secrets已添加：

- [ ] `ECS_HOST` = 119.3.174.235
- [ ] `ECS_USER` = root
- [ ] `ECS_PASSWORD` = whlRSK7.

---

## 🚀 工作流触发方式

### 自动触发

1. **Push到main/master分支**
   - 触发完整CI/CD流程
   - 执行: 代码检查 → 单元测试 → 构建 → 部署

2. **Pull Request**
   - 仅触发CI流程
   - 执行: 代码检查 → 单元测试 → 构建
   - 不执行部署

### 手动触发

1. 进入仓库 **Actions** 标签
2. 选择 **CI/CD Pipeline** 工作流
3. 点击 **Run workflow**
4. 可选择是否跳过测试（仅紧急情况使用）

---

## 📁 工作流文件结构

```
.github/
└── workflows/
    └── ci-cd.yml        # 主工作流配置
```

---

## 🔍 工作流详解

### CI阶段 (持续集成)

| Step | 说明 | 失败处理 |
|------|------|----------|
| 拉取代码 | Checkout最新代码 | 终止工作流 |
| 设置Node.js | 安装Node.js 18 | 终止工作流 |
| 缓存依赖 | 缓存node_modules | - |
| 安装依赖 | npm ci安装依赖 | 终止工作流 |
| 代码检查 | ESLint检查代码风格 | 终止工作流 |
| 单元测试 | Vitest执行测试用例 | 终止工作流 |
| 构建产物 | Vite构建生产版本 | 终止工作流 |
| 上传产物 | Artifact保存dist | 终止工作流 |

### CD阶段 (持续部署)

| Step | 说明 | 失败处理 |
|------|------|----------|
| 下载产物 | 下载CI构建的dist | 终止工作流 |
| 部署到ECS | SSH连接并准备环境 | 自动回滚 |
| 上传文件 | SCP传输dist到ECS | 自动回滚 |
| 重启服务 | 重载Nginx并健康检查 | 自动回滚 |
| 成功通知 | 生成部署报告 | - |

---

## 🛡️ 安全机制

### 1. Secrets加密存储

所有敏感信息存储在GitHub Secrets中，特性：
- ✅ 加密存储
- ✅ 不显示在工作流日志中
- ✅ 只有管理员可查看/修改
- ✅ Fork的仓库无法继承Secrets

### 2. 分支保护

建议配置main/master分支保护规则：
1. Settings → Branches → Add rule
2. Branch name pattern: `main`
3. 勾选:
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Require linear history

### 3. 并发控制

工作流配置了并发控制：
- 同一分支同时只能运行一个工作流
- 新工作流会取消旧的进行中工作流

---

## 🔄 回滚机制

### 自动回滚

部署失败时自动执行回滚：
1. 检测部署失败
2. 查找最新备份: `/var/www/task-kanban/backups/dist_*`
3. 恢复备份文件
4. 重载Nginx服务
5. 输出回滚通知

### 手动回滚

如需手动回滚到特定版本：

```bash
# SSH到ECS
ssh root@119.3.174.235

# 查看备份列表
ls -lt /var/www/task-kanban/backups/

# 回滚到指定版本（例如: dist_20260521_150000）
cd /var/www/task-kanban
rm -rf dist
cp -r backups/dist_20260521_150000 dist
nginx -t && systemctl reload nginx
```

---

## 📊 监控与日志

### 查看工作流运行状态

1. 进入仓库 **Actions** 标签
2. 查看工作流运行历史
3. 点击具体运行查看详细日志

### 关键日志标识

- 📦 安装依赖
- 🔍 代码检查
- 🧪 单元测试
- 🏗️ 构建产物
- 🚀 开始部署
- ✅ 部署成功
- ❌ 部署失败
- 🔄 回滚中

---

## ⚠️ 常见问题

### Q1: 工作流提示Secrets未配置

**解决**: 按照上述步骤配置ECS_HOST、ECS_USER、ECS_PASSWORD

### Q2: SSH连接失败

**检查**:
- ECS实例是否运行中
- 安全组是否开放22端口
- 密码是否正确

### Q3: 部署成功但页面无法访问

**检查**:
- Nginx是否运行: `systemctl status nginx`
- 应用目录权限: `ls -la /var/www/task-kanban`
- Nginx配置: `nginx -t`

### Q4: 如何查看当前部署版本

```bash
ssh root@119.3.174.235
cat /var/www/task-kanban/.version
```

---

## 🎯 后续优化建议

1. **使用SSH密钥认证** (更安全)
   - 生成SSH密钥对
   - 公钥添加到ECS: `~/.ssh/authorized_keys`
   - 私钥存储到GitHub Secrets: `SSH_PRIVATE_KEY`

2. **配置部署通知**
   - 集成Slack/钉钉Webhook
   - 部署成功/失败时发送通知

3. **添加性能测试**
   - 集成Lighthouse CI
   - 监控构建产物大小

4. **多环境部署**
   - 添加staging环境
   - 配置环境变量管理

---

## 📝 快速开始检查清单

- [ ] 项目已推送到GitHub
- [ ] 配置GitHub Secrets (ECS_HOST, ECS_USER, ECS_PASSWORD)
- [ ] 推送代码触发CI/CD
- [ ] 检查工作流运行状态
- [ ] 访问应用验证部署成功

配置完成后，每次push到main分支都会自动触发CI/CD流程！
