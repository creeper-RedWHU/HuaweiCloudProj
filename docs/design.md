# **1. 实现模型**

## **1.1 上下文视图**

### 系统上下文图

本CI/CD系统在整体应用部署架构中的位置：

```
┌─────────────────────────────────────────────────────────────────┐
│                        开发环境                                   │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │  开发人员电脑  │         │  Git客户端    │                     │
│  └──────┬───────┘         └──────┬───────┘                     │
│         │                        │                              │
└─────────┼────────────────────────┼──────────────────────────────┘
          │ git push               │
          ▼                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GitHub 平台                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  GitHub Repository                                        │  │
│  │  ├─ .github/workflows/ci-cd.yml  (工作流配置)              │  │
│  │  ├─ src/                        (Vue 3源码)               │  │
│  │  ├─ package.json                (依赖配置)                 │  │
│  │  └─ vite.config.ts              (构建配置)                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  GitHub Actions Runner (ubuntu-latest)                   │  │
│  │  ├─ checkout: 拉取代码                                    │  │
│  │  ├─ setup-node: 安装Node.js                               │  │
│  │  ├─ cache: 缓存依赖                                       │  │
│  │  ├─ lint: 代码检查                                        │  │
│  │  ├─ test: 单元测试                                        │  │
│  │  ├─ build: 构建产物                                       │  │
│  │  └─ deploy: 部署到ECS                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  GitHub Secrets (加密存储)                                │  │
│  │  ├─ SSH_PRIVATE_KEY                                      │  │
│  │  ├─ ECS_HOST                                             │  │
│  │  ├─ ECS_USER                                             │  │
│  │  └─ ECS_PASSWORD                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          │ SSH + rsync/scp
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    华为云 ECS 服务器                              │
│  IP: 119.3.174.235                                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  文件系统                                                 │  │
│  │  ├─ /var/www/task-kanban/         (应用根目录)            │  │
│  │  │  ├─ dist/                      (静态文件)              │  │
│  │  │  │  ├─ index.html                                       │  │
│  │  │  │  ├─ assets/*.js                                      │  │
│  │  │  │  └─ assets/*.css                                     │  │
│  │  │  ├─ .version                   (版本标记)               │  │
│  │  │  └─ backups/                  (回滚备份)               │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Nginx Web Server                                        │  │
│  │  ├─ 配置: /etc/nginx/sites-available/task-kanban         │  │
│  │  ├─ 监听端口: 80                                          │  │
│  │  └─ 根目录: /var/www/task-kanban/dist                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
          │ HTTP (端口80)
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                        用户访问                                   │
│                  http://119.3.174.235                            │
└─────────────────────────────────────────────────────────────────┘
```

### 组件交互序列图

```plantuml
@startuml
actor "开发人员" as dev
participant "Git客户端" as git
participant "GitHub\nRepository" as repo
participant "GitHub Actions\nRunner" as runner
participant "NPM仓库" as npm
participant "华为云ECS" as ecs
participant "Nginx" as nginx

== 代码提交阶段 ==
dev -> git : 编写代码
git -> repo : git push origin main
activate repo

== CI阶段 ==
repo -> runner : 触发workflow事件
activate runner

runner -> runner : checkout代码
runner -> npm : 下载依赖(利用缓存)
npm --> runner : 返回node_modules

runner -> runner : npm run lint\n(代码检查)
runner -> runner : npm run test\n(单元测试)
runner -> runner : npm run build\n(构建dist)

== CD阶段 ==
runner -> ecs : SSH连接(使用密钥)
activate ecs
ecs --> runner : 连接成功

runner -> ecs : 备份旧版本到backups/
runner -> ecs : 传输dist目录\n(使用rsync)
ecs --> runner : 文件传输完成

runner -> ecs : 更新.version文件
runner -> ecs : 执行健康检查脚本
ecs -> nginx : nginx -s reload
activate nginx
nginx --> ecs : 重载成功
nginx -> nginx : 服务新内容

ecs --> runner : 部署成功
deactivate ecs

runner -> repo : 更新workflow状态
runner -> runner : 发送通知\n(可选)
deactivate runner
deactivate repo

== 访问阶段 ==
dev -> nginx : HTTP请求
nginx --> dev : 返回Vue应用页面

@enduml
```

## **1.2 服务/组件总体架构**

### GitHub Actions工作流架构

```
┌─────────────────────────────────────────────────────────────────┐
│                   GitHub Actions Workflow                        │
│                  (.github/workflows/ci-cd.yml)                   │
└─────────────────────────────────────────────────────────────────┘
                               │
                ┌──────────────┴──────────────┐
                │                             │
                ▼                             ▼
    ┌─────────────────────┐       ┌─────────────────────┐
    │   CI Job (ci)       │       │   CD Job (deploy)   │
    └─────────────────────┘       └─────────────────────┘
                │                             │
     ┌──────────┼──────────┐                  │
     │          │          │                  │
     ▼          ▼          ▼                  ▼
┌─────────┐ ┌─────────┐ ┌─────────┐   ┌─────────────────┐
│ checkout│ │  setup  │ │  cache  │   │  deploy-to-ecs  │
│         │ │  node   │ │         │   │                 │
└─────────┘ └─────────┘ └─────────┘   └─────────────────┘
     │          │          │                  │
     │          ▼          ▼                  │
     │    ┌─────────┐ ┌─────────┐             │
     │    │  install│ │ restore │             │
     │    │  deps   │ │  cache  │             │
     │    └─────────┘ └─────────┘             │
     │          │                             │
     └──────────┼─────────────────────────────┘
                │
     ┌──────────┼──────────┐
     │          │          │
     ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│  lint   │ │  test   │ │  build  │
│ check   │ │  run    │ │  prod   │
└─────────┘ └─────────┘ └─────────┘
```

### Job依赖关系

```plantuml
@startuml
!define JOB rectangle

JOB "checkout" as checkout
JOB "setup-node" as setup
JOB "cache" as cache
JOB "install" as install
JOB "lint" as lint
JOB "test" as test
JOB "build" as build
JOB "deploy" as deploy

checkout --> setup
setup --> cache
cache --> install
install --> lint
install --> test
lint --> build
test --> build
build --> deploy

note right of checkout : 拉取代码
note right of setup : 安装Node.js 20
note right of cache : 缓存node_modules
note right of lint : ESLint检查
note right of test : Vitest测试
note right of build : Vite构建
note right of deploy : 部署到ECS

@enduml
```

### 技术栈选型

| 组件类型 | 技术选型 | 版本 | 选型理由 |
|---------|---------|------|---------|
| CI平台 | GitHub Actions | N/A | 原生GitHub集成，免费额度充足，社区Actions丰富 |
| Runner | GitHub-hosted | ubuntu-latest | 无需维护Runner，性能稳定，预装常用工具 |
| Node.js | Node.js | 20.x LTS | Vue 3官方推荐，长期支持版本 |
| 包管理器 | npm | 10.x | 项目统一标准，兼容性好 |
| 构建工具 | Vite | 5.x | Vue 3官方推荐，构建速度快 |
| 代码检查 | ESLint | 8.x | Vue生态标准，可配置性强 |
| 单元测试 | Vitest | 1.x | Vite原生集成，速度极快 |
| SSH工具 | appleboy/ssh-action | v1.0.0 | 社区维护良好，支持密钥和密码认证 |
| 文件传输 | rsync | 内置 | 增量传输，带宽占用低，支持断点续传 |
| Web服务器 | Nginx | 1.18+ | 高性能静态文件服务，配置简单 |
| 缓存策略 | actions/cache | v4 | 官方缓存Action，支持多路径缓存 |

## **1.3 实现设计文档**

### 1.3.1 GitHub Actions工作流设计

#### 完整工作流YAML配置

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:
    inputs:
      skip_tests:
        description: '跳过测试（仅在紧急情况下使用）'
        required: false
        default: 'false'
        type: boolean

# 并发控制：同一分支同时只能运行一个工作流
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  NODE_VERSION: '20'
  APP_DIR: '/var/www/task-kanban'
  ECS_HOST: ${{ secrets.ECS_HOST }}
  ECS_USER: ${{ secrets.ECS_USER }}

jobs:
  # ==================== CI阶段 ====================
  ci:
    name: 持续集成
    runs-on: ubuntu-latest
    
    steps:
      # Step 1: 拉取代码
      - name: 拉取代码
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # 获取完整历史用于版本标记

      # Step 2: 设置Node.js环境
      - name: 设置Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: 'package-lock.json'

      # Step 3: 缓存node_modules
      - name: 缓存依赖
        uses: actions/cache@v4
        id: cache-deps
        with:
          path: |
            node_modules
            ~/.npm
          key: ${{ runner.os }}-node-${{ env.NODE_VERSION }}-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-${{ env.NODE_VERSION }}-
            ${{ runner.os }}-node-

      # Step 4: 安装依赖
      - name: 安装依赖
        if: steps.cache-deps.outputs.cache-hit != 'true'
        run: |
          echo "📦 安装项目依赖..."
          npm ci --prefer-offline
          echo "✅ 依赖安装完成"

      # Step 5: 代码检查
      - name: 代码风格检查 (ESLint)
        run: |
          echo "🔍 执行ESLint检查..."
          npm run lint
          echo "✅ 代码检查通过"
        continue-on-error: false

      # Step 6: 单元测试
      - name: 单元测试 (Vitest)
        if: ${{ github.event.inputs.skip_tests != 'true' }}
        run: |
          echo "🧪 执行单元测试..."
          npm run test:unit -- --coverage
          echo "✅ 测试通过"
        continue-on-error: false

      # Step 7: 构建生产版本
      - name: 构建生产版本
        run: |
          echo "🏗️  构建生产版本..."
          npm run build
          echo "✅ 构建完成"
          echo "📊 构建产物大小:"
          du -sh dist/
        env:
          NODE_ENV: production

      # Step 8: 上传构建产物
      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.sha }}
          path: dist/
          retention-days: 7
          if-no-files-found: error

      # Step 9: 构建摘要
      - name: 生成构建摘要
        run: |
          echo "## 📋 构建摘要" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **提交SHA**: \`${{ github.sha }}\`" >> $GITHUB_STEP_SUMMARY
          echo "- **分支**: \`${{ github.ref_name }}\`" >> $GITHUB_STEP_SUMMARY
          echo "- **触发者**: ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY
          echo "- **Node版本**: ${{ env.NODE_VERSION }}" >> $GITHUB_STEP_SUMMARY
          echo "- **构建时间**: $(date '+%Y-%m-%d %H:%M:%S')" >> $GITHUB_STEP_SUMMARY

  # ==================== CD阶段 ====================
  deploy:
    name: 持续部署
    runs-on: ubuntu-latest
    needs: ci
    # 仅在main分支push时执行部署
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
      # Step 1: 下载构建产物
      - name: 下载构建产物
        uses: actions/download-artifact@v4
        with:
          name: dist-${{ github.sha }}
          path: dist/

      # Step 2: 创建部署脚本
      - name: 创建部署脚本
        run: |
          cat > deploy.sh << 'EOF'
          #!/bin/bash
          set -e
          
          APP_DIR="${APP_DIR}"
          BACKUP_DIR="${APP_DIR}/backups"
          TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
          COMMIT_SHA="${COMMIT_SHA}"
          
          echo "🚀 开始部署..."
          echo "📁 应用目录: $APP_DIR"
          echo "🔖 提交SHA: $COMMIT_SHA"
          
          # 创建备份目录
          mkdir -p "$BACKUP_DIR"
          
          # 备份当前版本
          if [ -d "$APP_DIR/dist" ]; then
            echo "📦 备份当前版本..."
            BACKUP_NAME="dist_${TIMESTAMP}_${COMMIT_SHA:0:7}.tar.gz"
            tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$APP_DIR" dist
            echo "✅ 备份完成: $BACKUP_NAME"
            
            # 清理旧备份，只保留最近3个
            cd "$BACKUP_DIR"
            ls -t dist_*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -f
            echo "🧹 清理旧备份，保留最近3个版本"
          fi
          
          # 备份dist目录到临时位置
          if [ -d "$APP_DIR/dist" ]; then
            mv "$APP_DIR/dist" "$APP_DIR/dist.old"
          fi
          
          # 创建版本标记文件
          echo "{\"commit\":\"$COMMIT_SHA\",\"time\":\"$TIMESTAMP\",\"deployer\":\"${DEPLOYER}\"}" > "$APP_DIR/.version"
          
          echo "✅ 部署脚本执行完成"
          EOF
          
          chmod +x deploy.sh

      # Step 3: 部署到ECS
      - name: 部署到华为云ECS
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.ECS_HOST }}
          username: ${{ secrets.ECS_USER }}
          password: ${{ secrets.ECS_PASSWORD }}
          script: |
            # 执行部署前准备
            export APP_DIR="${{ env.APP_DIR }}"
            export COMMIT_SHA="${{ github.sha }}"
            export DEPLOYER="${{ github.actor }}"
            ${{ steps.prepare.outputs.script }}

      # Step 4: 传输构建文件
      - name: 传输构建文件到ECS
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.ECS_HOST }}
          username: ${{ secrets.ECS_USER }}
          password: ${{ secrets.ECS_PASSWORD }}
          source: "dist/*"
          target: ${{ env.APP_DIR }}
          strip_components: 1
          rm: true

      # Step 5: 重启Nginx并验证
      - name: 重启Nginx并验证部署
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.ECS_HOST }}
          username: ${{ secrets.ECS_USER }}
          password: ${{ secrets.ECS_PASSWORD }}
          script: |
            set -e
            
            echo "🔄 重载Nginx配置..."
            
            # 测试Nginx配置
            if nginx -t; then
              echo "✅ Nginx配置验证通过"
              
              # 重载Nginx
              systemctl reload nginx || nginx -s reload
              echo "✅ Nginx重载成功"
            else
              echo "❌ Nginx配置验证失败，回滚..."
              if [ -d "${{ env.APP_DIR }}/dist.old" ]; then
                rm -rf "${{ env.APP_DIR }}/dist"
                mv "${{ env.APP_DIR }}/dist.old" "${{ env.APP_DIR }}/dist"
                systemctl reload nginx || nginx -s reload
                echo "✅ 已回滚到上一版本"
              fi
              exit 1
            fi
            
            # 清理临时备份
            rm -rf "${{ env.APP_DIR }}/dist.old"

      # Step 6: 健康检查
      - name: 健康检查
        run: |
          echo "🏥 执行健康检查..."
          
          # 等待服务启动
          sleep 5
          
          # 检查HTTP状态
          HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${{ secrets.ECS_HOST }})
          
          if [ "$HTTP_CODE" -eq 200 ]; then
            echo "✅ 健康检查通过 (HTTP $HTTP_CODE)"
          else
            echo "❌ 健康检查失败 (HTTP $HTTP_CODE)"
            exit 1
          fi

      # Step 7: 部署通知
      - name: 发送部署成功通知
        if: success()
        run: |
          echo "📧 部署成功通知"
          echo "- 应用地址: http://${{ secrets.ECS_HOST }}"
          echo "- 提交SHA: ${{ github.sha }}"
          echo "- 部署时间: $(date '+%Y-%m-%d %H:%M:%S')"

      - name: 发送部署失败通知
        if: failure()
        run: |
          echo "🚨 部署失败通知"
          echo "- 错误发生在步骤: ${{ job.status }}"
          echo "- 提交SHA: ${{ github.sha }}"
          echo "- 请检查GitHub Actions日志"

      # Step 8: 部署摘要
      - name: 生成部署摘要
        run: |
          echo "## 🚀 部署摘要" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "- **环境**: 生产环境" >> $GITHUB_STEP_SUMMARY
          echo "- **服务器**: ${{ secrets.ECS_HOST }}" >> $GITHUB_STEP_SUMMARY
          echo "- **应用目录**: ${{ env.APP_DIR }}" >> $GITHUB_STEP_SUMMARY
          echo "- **提交SHA**: \`${{ github.sha }}\`" >> $GITHUB_STEP_SUMMARY
          echo "- **部署者**: ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY
          echo "- **访问地址**: http://${{ secrets.ECS_HOST }}" >> $GITHUB_STEP_SUMMARY
```

### 1.3.2 分支保护配置

#### GitHub仓库设置

```yaml
# 分支保护规则配置 (通过GitHub Web界面设置)
branch_protection:
  branch: main
  rules:
    # 必须通过CI检查才能合并
    required_status_checks:
      strict: true
      contexts:
        - "持续集成"  # 对应CI Job名称
    
    # 必须通过Pull Request审查
    required_pull_request_reviews:
      dismiss_stale_reviews: true
      require_code_owner_reviews: false
      required_approving_review_count: 1
    
    # 其他保护规则
    enforce_admins: false
    required_linear_history: true
    allow_force_pushes: false
    allow_deletions: false
```

### 1.3.3 部署脚本详细设计

#### SSH连接配置

```bash
# SSH连接参数
SSH_CONFIG:
  host: ${{ secrets.ECS_HOST }}        # 119.3.174.235
  user: ${{ secrets.ECS_USER }}        # root
  port: 22
  auth_method: password                # 或 private_key
  
  # 密钥认证配置
  private_key: ${{ secrets.SSH_PRIVATE_KEY }}
  
  # 密码认证配置
  password: ${{ secrets.ECS_PASSWORD }}
  
  # 连接超时设置
  connect_timeout: 30s
  command_timeout: 10m
```

#### 文件传输策略

```bash
# rsync传输配置
RSYNC_CONFIG:
  # 增量传输，仅传输变更文件
  options:
    - "-avz"                    # 归档模式+压缩传输
    - "--delete"                # 删除目标端多余文件
    - "--exclude='.git'"        # 排除Git目录
    - "--exclude='node_modules'" # 排除依赖目录
    - "--timeout=300"           # 传输超时5分钟
  
  # 源路径
  source: "./dist/"
  
  # 目标路径
  target: "${ECS_USER}@${ECS_HOST}:${APP_DIR}/dist/"
```

#### 回滚机制设计

```bash
#!/bin/bash
# rollback.sh - 回滚脚本

set -e

APP_DIR="/var/www/task-kanban"
BACKUP_DIR="$APP_DIR/backups"

# 列出可用备份
echo "📋 可用备份列表:"
ls -lht "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "无可用备份"

# 选择备份版本（默认选择最新的）
BACKUP_FILE=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n 1)

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ 未找到备份文件"
  exit 1
fi

echo "📦 将回滚到: $BACKUP_FILE"

# 执行回滚
echo "🔄 开始回滚..."
rm -rf "$APP_DIR/dist"
tar -xzf "$BACKUP_FILE" -C "$APP_DIR"

# 重载Nginx
systemctl reload nginx || nginx -s reload

echo "✅ 回滚完成"
```

### 1.3.4 Nginx配置示例

```nginx
# /etc/nginx/sites-available/task-kanban

server {
    listen 80;
    server_name 119.3.174.235;
    
    root /var/www/task-kanban/dist;
    index index.html;
    
    # 日志配置
    access_log /var/log/nginx/task-kanban-access.log;
    error_log /var/log/nginx/task-kanban-error.log;
    
    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    gzip_min_length 1000;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Vue Router history模式支持
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 健康检查端点
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

# **2. 接口设计**

## **2.1 总体设计**

### GitHub Secrets配置清单

| Secret名称 | 类型 | 必填 | 说明 | 配置示例 |
|-----------|------|------|------|---------|
| `SSH_PRIVATE_KEY` | SSH私钥 | 否* | 用于SSH密钥认证的私钥 | `-----BEGIN RSA PRIVATE KEY-----\n...` |
| `ECS_HOST` | IP地址 | 是 | 华为云ECS公网IP | `119.3.174.235` |
| `ECS_USER` | 用户名 | 是 | SSH登录用户名 | `root` |
| `ECS_PASSWORD` | 密码 | 否* | SSH密码认证密码 | `whlRSK7.` |
| `NOTIFICATION_WEBHOOK` | URL | 否 | 通知Webhook地址 | `https://hooks.slack.com/...` |

> **注意**: `SSH_PRIVATE_KEY`和`ECS_PASSWORD`至少配置一个，优先使用密钥认证

### 工作流输入参数

```yaml
inputs:
  skip_tests:
    description: '跳过测试（仅在紧急情况下使用）'
    required: false
    default: 'false'
    type: boolean
```

### 工作流输出

| 输出项 | 类型 | 说明 |
|--------|------|------|
| 构建产物 | Artifact | dist目录，保留7天 |
| 构建日志 | Logs | GitHub Actions日志，保留30天 |
| 部署版本 | File | 服务器端.version文件 |
| 备份文件 | Archive | 最近3个版本的tar.gz备份 |

## **2.2 接口清单**

### 2.2.1 GitHub Actions工作流接口

#### 触发接口

```yaml
# Push触发
POST /repos/{owner}/{repo}/dispatches
Event: push
Branch: main
Payload:
  ref: refs/heads/main
  commits: [...]

# Pull Request触发
POST /repos/{owner}/{repo}/dispatches
Event: pull_request
Action: [opened, synchronize, reopened]
Payload:
  pull_request:
    number: 123
    head: { ref: "feature/xxx" }
    base: { ref: "main" }

# 手动触发
POST /repos/{owner}/{repo}/actions/workflows/ci-cd.yml/dispatches
Payload:
  ref: main
  inputs:
    skip_tests: false
```

#### 状态查询接口

```bash
# 查询工作流运行状态
GET /repos/{owner}/{repo}/actions/runs/{run_id}

Response:
{
  "id": 123456,
  "status": "completed",        # queued, in_progress, completed
  "conclusion": "success",      # success, failure, cancelled
  "head_branch": "main",
  "head_sha": "abc123...",
  "event": "push",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:05:00Z"
}
```

### 2.2.2 SSH部署接口

#### 部署命令接口

```bash
# SSH命令序列
COMMANDS=(
  # 1. 备份当前版本
  "tar -czf ${BACKUP_DIR}/dist_${TIMESTAMP}.tar.gz -C ${APP_DIR} dist"
  
  # 2. 清理目标目录
  "rm -rf ${APP_DIR}/dist/*"
  
  # 3. 创建版本标记
  "echo '{\"commit\":\"${SHA}\",\"time\":\"${TIMESTAMP}\"}' > ${APP_DIR}/.version"
  
  # 4. 重载Nginx
  "nginx -t && systemctl reload nginx"
  
  # 5. 健康检查
  "curl -f http://localhost/health || exit 1"
)
```

### 2.2.3 健康检查接口

```bash
# HTTP健康检查
GET http://{ECS_HOST}/health

Response:
  Status: 200 OK
  Body: "healthy"

# 应用可访问性检查
GET http://{ECS_HOST}/

Response:
  Status: 200 OK
  Content-Type: text/html
  Body: <Vue应用HTML>
```

### 2.2.4 回滚接口

```bash
# 手动回滚命令
ssh ${ECS_USER}@${ECS_HOST} "bash ${APP_DIR}/rollback.sh [backup_file]"

# 参数说明
Arguments:
  backup_file: 可选，指定备份文件名，默认使用最新备份

# 执行流程
1. 列出可用备份
2. 选择目标备份版本
3. 解压备份到应用目录
4. 重载Nginx
5. 验证服务可用
```

# **4. 数据模型**

## **4.1 设计目标**

### 数据存储需求

1. **构建产物存储**: dist目录静态文件
2. **版本信息存储**: commit SHA、部署时间、部署者
3. **备份文件存储**: 最近N个版本的完整备份
4. **日志存储**: 构建日志、部署日志、访问日志

### 数据流转关系

```
源代码 (Git)
    ↓ checkout
工作目录 (Runner)
    ↓ npm run build
构建产物 (dist/)
    ↓ upload artifact
Artifacts (GitHub)
    ↓ download artifact
工作目录 (Runner)
    ↓ rsync/scp
应用目录 (ECS)
    ↓ Nginx
用户访问 (HTTP)
```

## **4.2 模型实现**

### 4.2.1 构建产物数据模型

```
dist/
├── index.html                    # 入口HTML
├── assets/
│   ├── index-[hash].js           # 应用主JS
│   ├── index-[hash].css          # 应用主CSS
│   ├── vendor-[hash].js          # 第三方依赖JS
│   └── [name]-[hash].[ext]       # 其他资源
├── favicon.ico                   # 网站图标
└── [other-static-files]          # 其他静态资源

数据特征:
- 总大小: < 50MB
- 文件数量: < 500
- 包含内容: HTML + CSS + JS + 图片 + 字体
- 外部依赖: 无（完全独立）
```

### 4.2.2 版本信息数据模型

```json
// /var/www/task-kanban/.version
{
  "commit": "abc123def456789...",      // Git commit SHA (40字符)
  "time": "20240101_120000",           // 部署时间戳
  "deployer": "username",              // 部署执行者
  "branch": "main",                    // 来源分支
  "message": "feat: add new feature"   // 提交信息（可选）
}

字段说明:
- commit: 必填，用于版本追溯和问题定位
- time: 必填，格式YYYYMMDD_HHMMSS
- deployer: 必填，触发部署的GitHub用户
- branch: 可选，默认为main
- message: 可选，最新提交信息
```

### 4.2.3 备份数据模型

```
/var/www/task-kanban/backups/
├── dist_20240101_120000_abc123d.tar.gz    # 备份文件
├── dist_20240102_130000_def456e.tar.gz
└── dist_20240103_140000_ghi789f.tar.gz

命名规则: dist_{timestamp}_{short_sha}.tar.gz
- timestamp: YYYYMMDD_HHMMSS
- short_sha: commit SHA前7位

保留策略:
- 保留数量: 最近3个版本
- 清理时机: 每次部署成功后
- 存储位置: ECS服务器本地磁盘

压缩内容:
- dist/目录完整内容
- 保留文件权限和时间戳
```

### 4.2.4 日志数据模型

```
GitHub Actions日志 (保留30天)
├── workflow-run-{id}/
│   ├── job-ci.log           # CI阶段完整日志
│   └── job-deploy.log       # CD阶段完整日志

ECS服务器日志 (保留7天)
├── /var/log/nginx/
│   ├── task-kanban-access.log    # 访问日志
│   └── task-kanban-error.log     # 错误日志
└── /var/log/deploy/
    ├── deploy-{timestamp}.log    # 部署日志
    └── rollback-{timestamp}.log  # 回滚日志

日志格式:
- 时间戳: ISO 8601格式
- 日志级别: INFO/WARN/ERROR
- 结构化: JSON格式便于解析
```

### 4.2.5 缓存数据模型

```
GitHub Actions缓存
├── key: {os}-node-{version}-{package-lock-hash}
├── path:
│   ├── node_modules/          # 依赖目录
│   └── ~/.npm/                # npm缓存
└── ttl: 7天

缓存策略:
- 缓存键: package-lock.json的hash值
- 命中条件: 依赖未变更
- 失效条件: package.json或package-lock.json变更
- 大小限制: 单个缓存<10GB，总缓存<10GB
```

### 4.2.6 工作流配置数据模型

```yaml
# 数据流向
.github/workflows/ci-cd.yml
  ├── env:                        # 全局环境变量
  │   ├── NODE_VERSION: "20"
  │   ├── APP_DIR: "/var/www/task-kanban"
  │   ├── ECS_HOST: ${{ secrets.ECS_HOST }}
  │   └── ECS_USER: ${{ secrets.ECS_USER }}
  ├── jobs:                       # Job定义
  │   ├── ci:                     # CI Job
  │   │   ├── runs-on: ubuntu-latest
  │   │   ├── steps: [...]        # 步骤列表
  │   │   └── outputs: [...]      # 输出变量
  │   └── deploy:                 # CD Job
  │       ├── needs: ci           # 依赖关系
  │       ├── if: push to main    # 触发条件
  │       └── steps: [...]        # 步骤列表
  └── concurrency:                # 并发控制
      ├── group: workflow-ref
      └── cancel-in-progress: true

配置验证规则:
- YAML语法必须正确
- Job依赖关系不能有循环
- Secrets引用必须存在
- 环境变量不能包含敏感信息
```

---

# **5. 安全设计**

## **5.1 Secrets安全配置**

### 5.1.1 Secrets配置步骤

```bash
# 通过GitHub Web界面配置
Settings -> Secrets and variables -> Actions -> New repository secret

# 通过GitHub CLI配置
gh secret set SSH_PRIVATE_KEY < private_key.pem
gh secret set ECS_HOST -b "119.3.174.235"
gh secret set ECS_USER -b "root"
gh secret set ECS_PASSWORD -b "whlRSK7."
```

### 5.1.2 Secrets访问权限

| 访问场景 | 权限 | 说明 |
|---------|------|------|
| 工作流运行时 | ✅ 可读 | 通过`${{ secrets.XXX }}`访问 |
| 工作流日志 | ❌ 自动脱敏 | GitHub自动将Secrets值替换为`***` |
| Fork仓库 | ❌ 不可访问 | Secrets不会传递到Fork仓库 |
| Pull Request | ⚠️ 受限 | 来自Fork的PR无法访问Secrets |
| API访问 | ❌ 禁止 | 无法通过API读取Secrets值 |

### 5.1.3 SSH密钥安全要求

```bash
# 生成SSH密钥对（推荐）
ssh-keygen -t rsa -b 4096 -C "github-actions" -f github-actions-key

# 将公钥添加到ECS服务器
ssh-copy-id -i github-actions-key.pub root@119.3.174.235

# 或手动添加到authorized_keys
cat github-actions-key.pub | ssh root@119.3.174.235 \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 私钥添加到GitHub Secrets（包含BEGIN/END标记）
gh secret set SSH_PRIVATE_KEY < github-actions-key

# 清理本地私钥文件
rm github-actions-key
```

## **5.2 权限控制**

### 5.2.1 ECS服务器权限

```bash
# SSH用户权限范围
- 应用目录读写: /var/www/task-kanban/
- Nginx重载权限: systemctl reload nginx 或 nginx -s reload
- 日志目录读写: /var/log/nginx/, /var/log/deploy/
- 禁止: 系统配置修改、其他应用目录访问

# 推荐创建专用部署用户
useradd -m -s /bin/bash deploy
chown -R deploy:deploy /var/www/task-kanban
echo 'deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl reload nginx' >> /etc/sudoers
```

### 5.2.2 GitHub仓库权限

```
角色权限矩阵:
┌─────────────┬──────────┬──────────┬──────────┐
│   操作      │  Admin   │  Write   │  Read    │
├─────────────┼──────────┼──────────┼──────────┤
│ 配置Secrets │    ✅    │    ❌    │    ❌    │
│ 修改workflow│    ✅    │    ✅    │    ❌    │
│ 触发workflow│    ✅    │    ✅    │    ❌    │
│ 查看日志    │    ✅    │    ✅    │    ✅    │
│ 访问Artifacts│   ✅    │    ✅    │    ✅    │
└─────────────┴──────────┴──────────┴──────────┘
```

## **5.3 日志脱敏**

### 5.3.1 自动脱敏机制

```bash
# GitHub Actions自动脱敏规则
- Secrets值自动替换为 ***
- 环境变量中的Secrets不显示在日志中
- Print/echo输出包含Secrets时自动替换

# 示例
echo "Deploying to ${{ secrets.ECS_HOST }}"
# 日志输出: Deploying to ***
```

### 5.3.2 敏感信息避免清单

```yaml
# ❌ 不要在日志中输出
- echo "Password: ${{ secrets.ECS_PASSWORD }}"
- echo "Key: ${{ secrets.SSH_PRIVATE_KEY }}"

# ✅ 安全的做法
- echo "Deploying to server..."
- echo "Connection established"
- echo "Deployment completed"
```

---

# **6. 性能优化设计**

## **6.1 缓存优化**

### 6.1.1 依赖缓存策略

```yaml
# 多层缓存策略
cache:
  # 第一层: npm缓存
  - uses: actions/cache@v4
    with:
      path: ~/.npm
      key: npm-${{ hashFiles('**/package-lock.json') }}
  
  # 第二层: node_modules缓存
  - uses: actions/cache@v4
    with:
      path: node_modules
      key: modules-${{ runner.os }}-${{ env.NODE_VERSION }}-${{ hashFiles('**/package-lock.json') }}
  
  # 第三层: 构建缓存（Vite）
  - uses: actions/cache@v4
    with:
      path: node_modules/.vite
      key: vite-${{ hashFiles('**/package-lock.json') }}
```

### 6.1.2 缓存命中率优化

```
预期缓存效果:
┌────────────────────┬─────────┬─────────┐
│      场景          │ 无缓存  │ 有缓存  │
├────────────────────┼─────────┼─────────┤
│ npm install        │   60s   │   5s    │
│ npm run build      │   45s   │   30s   │
│ 总构建时间         │  105s   │   35s   │
└────────────────────┴─────────┴─────────┘

缓存命中率目标: > 70%
```

## **6.2 并行执行优化**

### 6.2.1 Job并行策略

```yaml
# 独立Job并行执行
jobs:
  lint:
    runs-on: ubuntu-latest
    steps: [...]  # 代码检查
  
  test:
    runs-on: ubuntu-latest
    steps: [...]  # 单元测试
  
  build:
    needs: [lint, test]  # 依赖lint和test
    runs-on: ubuntu-latest
    steps: [...]  # 构建
  
  deploy:
    needs: build  # 依赖build
    runs-on: ubuntu-latest
    steps: [...]  # 部署

# 执行时间轴
Time: 0----5----10---15---20---25 (分钟)
      ├lint────┤
      ├test────┤
      ├────build─────┤
      ├─────deploy────┤
```

### 6.2.2 Step并行优化

```yaml
# 可以并行的步骤
- name: 并行检查
  run: |
    # 使用GNU Parallel并行执行
    npm run lint &
    npm run type-check &
    wait
```

## **6.3 构建优化**

### 6.3.1 Vite构建配置

```typescript
// vite.config.ts 构建优化
export default defineConfig({
  build: {
    // 代码分割
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['vue', 'vue-router', 'pinia'],
          'ui': ['element-plus'],
        }
      }
    },
    // 压缩配置
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,  // 移除console
        drop_debugger: true  // 移除debugger
      }
    },
    // 产物报告
    reportCompressedSize: true,
    // chunk大小警告阈值
    chunkSizeWarningLimit: 500
  }
})
```

### 6.3.2 构建性能指标

```
目标构建性能:
┌─────────────────┬──────────┐
│     指标        │   目标   │
├─────────────────┼──────────┤
│ 总构建时间      │  < 2min  │
│ 产物大小        │  < 50MB  │
│ chunk数量       │  < 20    │
│ 最大chunk       │  < 2MB   │
│ Gzip压缩率      │  > 70%   │
└─────────────────┴──────────┘
```

---

# **7. 监控与告警设计**

## **7.1 监控指标**

### 7.1.1 关键监控指标

```yaml
# 构建阶段监控
metrics:
  - name: build_duration
    type: gauge
    description: 构建总耗时
    unit: seconds
    threshold: < 300
    
  - name: build_success_rate
    type: ratio
    description: 构建成功率
    threshold: > 95%
    
  - name: cache_hit_rate
    type: ratio
    description: 缓存命中率
    threshold: > 70%

# 部署阶段监控
  - name: deploy_duration
    type: gauge
    description: 部署总耗时
    unit: seconds
    threshold: < 120
    
  - name: deploy_success_rate
    type: ratio
    description: 部署成功率
    threshold: > 98%
    
  - name: rollback_count
    type: counter
    description: 回滚次数
    threshold: 尽可能低

# 应用运行监控
  - name: http_response_time
    type: gauge
    description: HTTP响应时间
    unit: milliseconds
    threshold: < 500ms
    
  - name: http_success_rate
    type: ratio
    description: HTTP成功率
    threshold: > 99%
```

### 7.1.2 日志监控

```bash
# Nginx访问日志监控
tail -f /var/log/nginx/task-kanban-access.log | \
  grep -E " 5[0-9]{2} " && \
  echo "⚠️ 检测到5xx错误"

# 部署日志监控
tail -f /var/log/deploy/deploy-*.log | \
  grep -E "ERROR|FAIL" && \
  echo "🚨 检测到部署错误"
```

## **7.2 告警策略**

### 7.2.1 告警规则

```yaml
# GitHub Actions失败告警
alert_rules:
  - name: workflow_failure
    condition: workflow.conclusion == 'failure'
    severity: high
    notify:
      - github_issue        # 创建Issue
      - email               # 发送邮件
      - webhook             # Webhook通知
    
  - name: deployment_failure
    condition: deploy.conclusion == 'failure'
    severity: critical
    notify:
      - pagerduty          # 即时通知
      - sms                # 短信告警
      
  - name: health_check_failure
    condition: health_check.success == false
    severity: critical
    action: auto_rollback  # 自动回滚
    notify:
      - all_channels
```

### 7.2.2 通知渠道配置

```yaml
# 通知渠道
notification_channels:
  # GitHub Status Checks
  github_status:
    enabled: true
    show_in_pr: true
    
  # 邮件通知
  email:
    enabled: true
    recipients:
      - team@example.com
    on_events: [failure, recovery]
    
  # Slack/企业微信 Webhook
  webhook:
    enabled: true
    url: ${{ secrets.NOTIFICATION_WEBHOOK }}
    template: |
      {
        "text": "🚨 ${{ job.status }}",
        "attachments": [{
          "color": "${{ job.status == 'success' && 'good' || 'danger' }}",
          "fields": [
            {"title": "Repository", "value": "${{ github.repository }}"},
            {"title": "Branch", "value": "${{ github.ref }}"},
            {"title": "Commit", "value": "${{ github.sha }}"},
            {"title": "Author", "value": "${{ github.actor }}"}
          ]
        }]
      }
```

---

# **8. 故障处理设计**

## **8.1 常见故障场景**

### 8.1.1 故障场景与处理

| 故障场景 | 触发条件 | 自动处理 | 手动处理 |
|---------|---------|---------|---------|
| 依赖下载失败 | NPM仓库不可用 | 重试3次 | 切换npm镜像源 |
| SSH连接失败 | 密钥错误/网络不通 | 重试3次 | 检查Secrets配置 |
| 构建内存溢出 | 项目过大 | 增加swap | 拆分构建 |
| 文件传输中断 | 网络不稳定 | 自动续传 | 检查网络带宽 |
| Nginx配置错误 | 配置语法错误 | 自动回滚 | 修复配置文件 |
| 健康检查失败 | 应用无法访问 | 自动回滚 | 检查Nginx日志 |
| 磁盘空间不足 | 备份文件过多 | 清理旧备份 | 扩容磁盘 |

### 8.1.2 故障恢复SOP

```bash
# 标准故障恢复流程
1. 接收告警通知
2. 查看GitHub Actions日志定位问题
3. 根据故障类型选择处理方式:
   
   Case: 构建失败
   ├─ 查看构建日志
   ├─ 本地复现问题
   ├─ 修复代码或配置
   └─ 重新推送代码
   
   Case: 部署失败
   ├─ 检查Secrets配置
   ├─ 检查ECS服务器状态
   ├─ 必要时执行回滚
   └─ 修复问题后重新触发workflow
   
   Case: 应用异常
   ├─ 查看Nginx错误日志
   ├─ 查看应用访问日志
   ├─ 执行健康检查
   └─ 必要时回滚到上一版本

4. 记录故障原因和处理过程
5. 更新文档和监控策略
```

## **8.2 回滚操作手册**

### 8.2.1 自动回滚

```yaml
# 自动回滚触发条件
auto_rollback_conditions:
  - health_check_failed
  - nginx_reload_failed
  - critical_error_in_deployment

# 自动回滚流程
auto_rollback_flow:
  1. 识别失败原因
  2. 从backups/选择最新备份
  3. 解压备份文件到应用目录
  4. 重载Nginx服务
  5. 执行健康检查
  6. 发送回滚通知
```

### 8.2.2 手动回滚

```bash
# 登录ECS服务器
ssh root@119.3.174.235

# 查看可用备份
ls -lht /var/www/task-kanban/backups/

# 执行回滚脚本
cd /var/www/task-kanban
bash rollback.sh dist_20240101_120000_abc123d.tar.gz

# 或手动回滚
tar -xzf backups/dist_20240101_120000_abc123d.tar.gz -C .
systemctl reload nginx

# 验证应用可用
curl http://localhost/health
```

---

# **9. 扩展性设计**

## **9.1 多环境支持**

### 9.1.1 环境配置抽象

```yaml
# 环境配置
environments:
  production:
    ecs_host: ${{ secrets.ECS_HOST_PROD }}
    ecs_user: ${{ secrets.ECS_USER_PROD }}
    app_dir: /var/www/task-kanban
    url: http://119.3.174.235
    
  staging:
    ecs_host: ${{ secrets.ECS_HOST_STAGING }}
    ecs_user: ${{ secrets.ECS_USER_STAGING }}
    app_dir: /var/www/task-kanban-staging
    url: http://staging.example.com

# 工作流配置
deploy:
  strategy:
    matrix:
      environment: [production]
    include:
      - environment: production
        branch: main
      - environment: staging
        branch: develop
```

## **9.2 扩展功能规划**

### 9.2.1 未来可扩展功能

```yaml
# 阶段性功能扩展规划
phase_1:  # 当前实现
  - 基础CI/CD流程
  - 单环境部署
  - 手动触发支持

phase_2:  # 近期规划
  - 多环境部署（staging/production）
  - 部署审批流程
  - 蓝绿部署支持

phase_3:  # 中期规划
  - 容器化部署（Docker）
  - Kubernetes部署支持
  - 性能测试集成

phase_4:  # 长期规划
  - 多集群部署
  - 金丝雀发布
  - A/B测试支持
```

---

# **附录**

## A. 配置文件清单

| 文件路径 | 说明 | 必须 |
|---------|------|------|
| `.github/workflows/ci-cd.yml` | 主工作流配置 | ✅ |
| `package.json` | 项目依赖配置 | ✅ |
| `vite.config.ts` | Vite构建配置 | ✅ |
| `nginx.conf` | Nginx配置（服务器端） | ✅ |
| `rollback.sh` | 回滚脚本（服务器端） | ⚠️ |

## B. 参考资源

- [GitHub Actions官方文档](https://docs.github.com/en/actions)
- [appleboy/ssh-action](https://github.com/appleboy/ssh-action)
- [Vite构建优化](https://vitejs.dev/guide/build.html)
- [Vue 3部署指南](https://vuejs.org/guide/best-practices/production-deployment.html)
