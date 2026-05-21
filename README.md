# 任务管理看板 (Task Kanban)

一个基于Vue 3的看板应用，支持任务的拖拽管理、状态切换和数据持久化。

## 🌟 特性

- ✅ Vue 3 + Vite 构建
- ✅ 拖拽任务卡片
- ✅ 多列看板视图（待办、进行中、已完成）
- ✅ 本地数据持久化
- ✅ 单元测试覆盖
- ✅ GitHub Actions CI/CD
- ✅ 自动化部署到华为云ECS

## 🚀 快速开始

### 本地开发

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build

# 运行测试
npm run test
```

### 访问已部署应用

**生产环境**: http://119.3.174.235

---

## 📦 项目结构

```
task-kanban/
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions工作流
├── docs/
│   ├── spec.md                 # CI/CD需求规格
│   ├── design.md               # CI/CD技术设计
│   ├── GITHUB_ACTIONS_GUIDE.md # 详细配置指南
│   └── QUICK_START.md          # 快速开始指南
├── src/
│   ├── components/             # Vue组件
│   ├── composables/            # 组合式函数
│   ├── utils/                  # 工具函数
│   └── assets/                 # 静态资源
├── tests/                      # 测试文件
├── package.json
└── vite.config.js
```

---

## 🔄 CI/CD 工作流

### 自动化流程

```
Push → CI检查 → 测试 → 构建 → 部署 → 健康检查
```

### 触发规则

| 事件 | CI | CD | 说明 |
|------|----|----|------|
| Push到main | ✅ | ✅ | 完整流程，自动部署 |
| Pull Request | ✅ | ❌ | 仅CI检查，不部署 |
| 手动触发 | ✅ | ✅ | 可选择跳过测试 |

### 查看工作流

进入仓库 **Actions** 标签查看运行状态。

---

## 🌐 部署信息

### 生产环境

- **地址**: http://119.3.174.235
- **平台**: 华为云ECS
- **规格**: s6.large.2 (2核4G)
- **Web服务器**: Nginx
- **应用目录**: /var/www/task-kanban

### SSH访问

```bash
ssh root@119.3.174.235
# 密码: whlRSK7.
```

### 查看部署版本

```bash
ssh root@119.3.174.235
cat /var/www/task-kanban/.version
```

---

## 👥 团队协作

### 开发流程

1. **创建功能分支**
   ```bash
   git checkout -b feature/your-feature
   ```

2. **开发和提交**
   ```bash
   git add .
   git commit -m "Add your feature"
   git push origin feature/your-feature
   ```

3. **创建Pull Request**
   - GitHub上创建PR
   - CI自动执行检查
   - 等待Review

4. **合并和部署**
   - Review通过后合并
   - 自动部署到生产环境

### 分支保护

建议配置main分支保护：
- 要求PR通过CI检查
- 要求至少1个Review
- 禁止直接Push

---

## 🔧 配置GitHub Actions

### 必需的Secrets

在GitHub仓库 Settings → Secrets → Actions 中配置：

| Secret | 值 | 说明 |
|--------|-----|------|
| `ECS_HOST` | `119.3.174.235` | ECS公网IP |
| `ECS_USER` | `root` | SSH用户名 |
| `ECS_PASSWORD` | `whlRSK7.` | SSH密码 |

### 详细配置

请查看 [GitHub Actions配置指南](docs/GITHUB_ACTIONS_GUIDE.md) 或 [快速开始](docs/QUICK_START.md)

---

## 🛡️ 安全说明

- ✅ 密码存储在GitHub Secrets（加密）
- ✅ 工作流日志自动脱敏
- ✅ 部署失败自动回滚
- ✅ 保留最近3个版本备份

**⚠️ 注意**: 生产环境建议使用SSH密钥认证而非密码。

---

## 📊 监控和日志

### 查看工作流日志

1. GitHub仓库 → Actions
2. 选择具体的工作流运行
3. 展开各个Step查看详细日志

### 查看ECS日志

```bash
ssh root@119.3.174.235

# Nginx访问日志
tail -f /var/log/nginx/access.log

# Nginx错误日志
tail -f /var/log/nginx/error.log

# 应用版本
cat /var/www/task-kanban/.version
```

---

## 🔄 回滚操作

### 自动回滚

部署失败时自动执行：
- 恢复最近一次成功部署的版本
- 重载Nginx服务
- 记录回滚事件

### 手动回滚

```bash
ssh root@119.3.174.235

# 查看备份列表
ls -lt /var/www/task-kanban/backups/

# 回滚到指定版本
cd /var/www/task-kanban
rm -rf dist
cp -r backups/dist_TIMESTAMP dist
nginx -t && systemctl reload nginx
```

---

## 🧪 测试

### 本地测试

```bash
# 运行所有测试
npm run test

# 监听模式
npm run test:watch
```

### CI测试

每次PR和Push都会自动执行测试。

---

## 📝 文档

- [需求规格文档](docs/spec.md) - CI/CD功能需求
- [技术设计文档](docs/design.md) - 实现方案设计
- [GitHub Actions指南](docs/GITHUB_ACTIONS_GUIDE.md) - 详细配置说明
- [快速开始](docs/QUICK_START.md) - 快速启用CI/CD

---

## 💰 费用信息

### 华为云ECS (按需计费)

- ECS (s6.large.2): ¥0.16/小时
- 系统盘 (40GB GPSSD): ¥0.02/小时
- 数据盘 (40GB GPSSD): ¥0.02/小时
- 带宽 (5Mbps): ¥0.12/小时
- **合计**: ¥0.32/小时 ≈ ¥230/月

---

## 🤝 贡献

欢迎团队成员贡献代码！

1. Fork本仓库
2. 创建功能分支
3. 提交Pull Request
4. 等待CI检查和Review
5. 合并后自动部署

---

## 📄 许可证

MIT

---

## 🙋 常见问题

### Q: 如何更新应用？

A: 直接push到main分支，CI/CD会自动构建和部署。

### Q: 部署失败了怎么办？

A: 系统会自动回滚。查看Actions日志定位问题，修复后重新push。

### Q: 如何查看当前运行的版本？

A: 访问 http://119.3.174.235 或查看 `.version` 文件。

### Q: 如何添加新的团队成员？

A: 邀请加入GitHub仓库，配置好权限即可协作开发。

---

**Happy Coding! 🎉**
