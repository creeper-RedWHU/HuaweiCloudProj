# 快速启用GitHub Actions CI/CD

## 一、初始化Git仓库并推送到GitHub

### 1. 初始化本地仓库

```bash
cd D:/Temp/HuaweiCloudProj
git init
git add .
git commit -m "Initial commit: Task Kanban with CI/CD"
```

### 2. 创建GitHub仓库

1. 打开 https://github.com/new
2. Repository name: `task-kanban` (或自定义)
3. 选择 Public 或 Private
4. 不要勾选 "Add a README file"
5. 点击 **Create repository**

### 3. 推送到GitHub

```bash
# 替换 YOUR_USERNAME 为你的GitHub用户名
git remote add origin https://github.com/YOUR_USERNAME/task-kanban.git
git branch -M main
git push -u origin main
```

---

## 二、配置GitHub Secrets

### 必需配置（3个Secrets）

进入仓库 Settings → Secrets and variables → Actions，添加：

| Secret名称 | 值 | 说明 |
|-----------|-----|------|
| `ECS_HOST` | `119.3.174.235` | ECS公网IP |
| `ECS_USER` | `root` | SSH用户名 |
| `ECS_PASSWORD` | `whlRSK7.` | SSH密码 |

### 配置步骤

```
Settings → Secrets and variables → Actions → New repository secret
```

依次添加3个Secrets。

---

## 三、验证CI/CD工作流

### 1. 推送代码触发工作流

```bash
# 修改任意文件
echo "# Test CI/CD" >> README.md
git add .
git commit -m "Test CI/CD pipeline"
git push
```

### 2. 查看工作流状态

1. 进入GitHub仓库 **Actions** 标签
2. 查看 **CI/CD Pipeline** 工作流
3. 等待CI完成（约2-3分钟）
4. 确认部署成功

### 3. 验证应用访问

浏览器打开: http://119.3.174.235

---

## 四、工作流触发规则

| 触发方式 | CI | CD | 说明 |
|---------|----|----|------|
| Push到main | ✅ | ✅ | 完整流程 |
| Pull Request | ✅ | ❌ | 仅测试 |
| 手动触发 | ✅ | ✅ | 可选跳过测试 |

---

## 五、团队成员协作流程

### 开发者A: 创建功能分支

```bash
git checkout -b feature/add-task-priority
# 编写代码...
git add .
git commit -m "Add task priority feature"
git push origin feature/add-task-priority
```

### 开发者A: 创建Pull Request

1. GitHub上创建PR: `feature/add-task-priority` → `main`
2. CI自动执行代码检查和测试
3. PR页面显示检查状态

### 开发者B: Review并合并

1. 查看PR代码变更
2. 确认CI检查通过（绿色✅）
3. Approve并合并PR

### 自动部署

PR合并到main后，自动触发：
1. CI: 检查 + 测试 + 构建
2. CD: 部署到ECS
3. 健康检查
4. 失败自动回滚

---

## 六、文件清单

### 已创建的文件

```
.github/
└── workflows/
    └── ci-cd.yml                    # CI/CD工作流配置

docs/
├── spec.md                          # 需求规格文档
├── design.md                        # 技术设计文档
└── GITHUB_ACTIONS_GUIDE.md          # 详细配置指南
```

### 工作流特性

- ✅ 自动代码检查（ESLint）
- ✅ 自动单元测试（Vitest）
- ✅ 自动构建生产版本
- ✅ 自动部署到华为云ECS
- ✅ 部署失败自动回滚
- ✅ 缓存优化加速构建
- ✅ 详细日志和摘要

---

## 七、故障排查

### 工作流失败

1. 检查Actions日志，找到失败的Step
2. 常见原因：
   - Secrets未配置或配置错误
   - ECS无法访问（检查安全组）
   - 测试用例失败
   - 代码检查不通过

### 部署失败

1. 检查ECS状态: `ssh root@119.3.174.235`
2. 查看Nginx日志: `tail -f /var/log/nginx/error.log`
3. 查看应用目录: `ls -la /var/www/task-kanban/`
4. 手动回滚（见详细指南）

---

## 八、下一步

配置完成后：

1. **团队协作**: 邀请团队成员，设置分支保护
2. **监控告警**: 配置Slack/钉钉通知
3. **性能优化**: 添加Lighthouse CI
4. **多环境**: 添加staging环境

详细说明请查看: `docs/GITHUB_ACTIONS_GUIDE.md`
