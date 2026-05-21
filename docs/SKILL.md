# Skill: Vue应用部署到华为云ECS

一键部署Vue前端应用到华为云ECS，包含完整的基础设施创建、应用部署和CI/CD配置。

---

## 📋 适用场景

- Vue 3 / React 等前端应用部署
- 需要快速搭建生产环境
- 团队协作开发，需要CI/CD
- 华为云ECS单机部署

---

## 🎯 部署目标

- ✅ 自动创建华为云资源（VPC、ECS、EIP等）
- ✅ 自动安装运行环境（Node.js、Nginx）
- ✅ 自动部署Vue应用
- ✅ 配置GitHub Actions CI/CD
- ✅ 按需计费，成本可控

---

## 📦 前置准备

### 必需信息

| 准备项 | 获取方式 | 说明 |
|--------|----------|------|
| 华为云AK/SK | [华为云控制台](https://console.huaweicloud.com/iam/#/accessKey) | Access Key和Secret Key |
| GitHub仓库 | 已存在的项目仓库 | 需要push权限 |
| ECS登录密码 | 自定义 | 8-26位，含大小写字母+数字+特殊字符 |

### 本地环境

- Git
- Python 3.x
- Terraform 1.9.x（脚本会自动安装）

---

## 🚀 完整部署流程

### 阶段一：环境准备（约2分钟）

#### 1. 安装Terraform

**Windows平台**：

```python
# 下载Terraform（从HashiCorp官方）
import urllib.request
import zipfile
import os

url = 'https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_windows_amd64.zip'
path = 'D:/software/terraform.zip'

print('下载Terraform...')
urllib.request.urlretrieve(url, path)

# 解压
with zipfile.ZipFile(path, 'r') as zip_ref:
    zip_ref.extractall('D:/software/terraform')

print('Terraform安装完成: D:/software/terraform/terraform.exe')
```

**验证安装**：

```bash
D:/software/terraform/terraform.exe version
# 输出: Terraform v1.9.8
```

#### 2. 创建Terraform工作目录

```bash
mkdir -p D:/Temp/项目名/terraform
```

---

### 阶段二：配置Terraform（约3分钟）

#### 1. 下载Terraform模板

从部署技能包复制模板文件：

```bash
# 复制main.tf（资源定义）
cp skill-path/templates/terraform/single-ecs/main.tf 项目目录/terraform/

# 复制user_data_single.sh（ECS初始化脚本）
cp skill-path/templates/terraform/single-ecs/user_data_single.sh 项目目录/terraform/
```

**main.tf核心内容**：

```hcl
terraform {
  required_version = "1.9.8"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "1.90.0"
    }
  }
}

provider "huaweicloud" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

# 创建VPC
resource "huaweicloud_vpc" "main" {
  name = "${var.project_name}-vpc"
  cidr = "192.168.0.0/16"
}

# 创建子网
resource "huaweicloud_vpc_subnet" "main" {
  name       = "${var.project_name}-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = "192.168.1.0/24"
  gateway_ip = "192.168.1.1"
}

# 创建安全组（开放22/80/443端口）
resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.project_name}-sg"
  description = "应用安全组"
}

# 创建ECS
resource "huaweicloud_compute_instance" "web" {
  name              = "${var.project_name}-ecs"
  image_id          = data.huaweicloud_images_image.ubuntu.id
  flavor_id         = "s6.large.2"  # 2核4G
  security_group_ids = [huaweicloud_networking_secgroup.main.id]
  
  network {
    uuid = huaweicloud_vpc_subnet.main.id
  }
  
  system_disk_type = "GPSSD"
  system_disk_size = 40
  
  admin_pass = var.ecs_password
}

# 创建EIP并绑定
resource "huaweicloud_vpc_eip" "web" {
  publicip { type = "5_bgp" }
  bandwidth {
    size        = 5
    charge_mode = "bandwidth"
  }
}

resource "huaweicloud_compute_eip_associate" "web" {
  public_ip   = huaweicloud_vpc_eip.web.address
  instance_id = huaweicloud_compute_instance.web.id
}
```

#### 2. 创建terraform.tfvars（变量配置）

```hcl
# 华为云认证
access_key = "你的AccessKey"
secret_key = "你的SecretKey"

# ECS配置
ecs_password = "你的密码"  # 如: Test@123456

# 项目配置
region       = "cn-north-4"  # 华北-北京四
project_name = "task-kanban"
environment  = "dev"

# ECS规格（按需计费）
ecs_vcpu    = 2
ecs_memory  = 4

# 磁盘配置
system_disk_size = 40  # 系统盘40GB
data_disk_size   = 40  # 数据盘40GB

# 带宽配置
eip_bandwidth = 5  # 5Mbps

# 应用端口
app_port = 80  # Vue应用默认80端口
```

#### 3. 初始化并部署

```bash
cd 项目目录/terraform

# 初始化（下载Provider）
terraform init

# 部署资源（约2-3分钟）
terraform apply -auto-approve
```

**输出结果**：

```
Apply complete! Resources: 9 added.

Outputs:
  eip_address = "119.3.174.235"
  ecs_id = "46d60cbe-450d-4021-b2db-7b6844028409"
  access_url = "http://119.3.174.235"
  ssh_command = "ssh root@119.3.174.235"
```

**记录关键信息**：
- ECS公网IP：119.3.174.235
- SSH登录：root@119.3.174.235
- 登录密码：terraform.tfvars中设置的密码

---

### 阶段三：部署应用（约5分钟）

#### 1. 等待ECS就绪

```bash
# 等待2-3分钟让ECS完全启动
sleep 180
```

#### 2. SSH连接并安装环境

使用Python的paramiko库：

```python
import paramiko
import time

EIP = "119.3.174.235"
PASSWORD = "你的密码"

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(EIP, 22, "root", PASSWORD)

def run_command(cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    return stdout.read().decode(), stderr.read().decode()

# 安装Node.js 18
print("安装Node.js...")
run_command("curl -fsSL https://deb.nodesource.com/setup_18.x | bash -")
run_command("apt-get install -y nodejs")

# 安装Nginx
print("安装Nginx...")
run_command("apt-get update && apt-get install -y nginx")

# 创建应用目录
run_command("mkdir -p /var/www/task-kanban")

ssh.close()
```

#### 3. 上传应用代码

```python
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(EIP, 22, "root", PASSWORD)

sftp = ssh.open_sftp()

# 上传项目文件
local_dir = "D:/Temp/HuaweiCloudProj"
remote_dir = "/var/www/task-kanban"

# 创建远程目录结构
run_command(f"mkdir -p {remote_dir}/src/components")
run_command(f"mkdir -p {remote_dir}/src/composables")
run_command(f"mkdir -p {remote_dir}/src/utils")
run_command(f"mkdir -p {remote_dir}/src/assets")

# 上传文件
sftp.put(f"{local_dir}/package.json", f"{remote_dir}/package.json")
sftp.put(f"{local_dir}/vite.config.js", f"{remote_dir}/vite.config.js")
sftp.put(f"{local_dir}/index.html", f"{remote_dir}/index.html")
sftp.put(f"{local_dir}/src/main.js", f"{remote_dir}/src/main.js")
sftp.put(f"{local_dir}/src/App.vue", f"{remote_dir}/src/App.vue")

# 上传其他文件...

sftp.close()
ssh.close()
```

#### 4. 构建并部署

```python
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(EIP, 22, "root", PASSWORD)

def run_command(cmd):
    stdin, stdout, stderr = ssh.exec_command(cmd)
    return stdout.read().decode(), stderr.read().decode()

# 安装依赖
print("安装npm依赖...")
run_command(f"cd /var/www/task-kanban && npm install")

# 构建
print("构建应用...")
run_command(f"cd /var/www/task-kanban && npm run build")

# 配置Nginx
nginx_conf = """
server {
    listen 80;
    server_name _;
    root /var/www/task-kanban/dist;
    index index.html;
    
    large_client_header_buffers 4 32k;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
"""

run_command(f"echo '{nginx_conf}' > /etc/nginx/sites-available/task-kanban")
run_command("ln -sf /etc/nginx/sites-available/task-kanban /etc/nginx/sites-enabled/")
run_command("rm -f /etc/nginx/sites-enabled/default")
run_command("nginx -t && systemctl reload nginx")

ssh.close()
```

#### 5. 验证部署

```bash
# 访问应用
curl http://119.3.174.235/

# 应返回Vue应用的HTML
```

---

### 阶段四：配置CI/CD（约5分钟）

#### 1. 创建GitHub Actions工作流

创建文件 `.github/workflows/ci-cd.yml`：

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:

env:
  NODE_VERSION: '18'

jobs:
  # CI阶段
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: 设置Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: 安装依赖
        run: npm ci
      
      - name: 代码检查
        run: npm run lint
      
      - name: 单元测试
        run: npm run test
      
      - name: 构建
        run: npm run build
      
      - name: 上传构建产物
        uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.sha }}
          path: dist/

  # CD阶段
  deploy:
    needs: ci
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    
    steps:
      - name: 下载构建产物
        uses: actions/download-artifact@v4
        with:
          name: dist-${{ github.sha }}
          path: dist/
      
      - name: 部署到ECS
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.ECS_HOST }}
          username: ${{ secrets.ECS_USER }}
          password: ${{ secrets.ECS_PASSWORD }}
          script: |
            # 备份当前版本
            cp -r /var/www/task-kanban/dist /var/www/task-kanban/backups/dist_$(date +%Y%m%d_%H%M%S)
      
      - name: 上传文件
        uses: appleboy/scp-action@v0.1.4
        with:
          host: ${{ secrets.ECS_HOST }}
          username: ${{ secrets.ECS_USER }}
          password: ${{ secrets.ECS_PASSWORD }}
          source: "dist/*"
          target: "/var/www/task-kanban"
          strip_components: 1
      
      - name: 重启服务
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.ECS_HOST }}
          username: ${{ secrets.ECS_USER }}
          password: ${{ secrets.ECS_PASSWORD }}
          script: |
            echo "${{ github.sha }}" > /var/www/task-kanban/.version
            nginx -t && systemctl reload nginx
```

#### 2. 配置GitHub Secrets

进入 GitHub仓库 → Settings → Secrets and variables → Actions

添加3个Secrets：

| Secret名称 | 值 | 说明 |
|-----------|-----|------|
| `ECS_HOST` | `119.3.174.235` | ECS公网IP |
| `ECS_USER` | `root` | SSH用户名 |
| `ECS_PASSWORD` | `你的密码` | SSH密码 |

#### 3. 推送代码触发CI/CD

```bash
git add .github/workflows/ci-cd.yml
git commit -m "Add GitHub Actions CI/CD"
git push origin main
```

---

## 📊 部署结果验证

### 1. 检查应用访问

```bash
curl -I http://119.3.174.235
# 应返回: HTTP/1.1 200 OK
```

### 2. 检查CI/CD工作流

进入GitHub仓库 → Actions标签，查看工作流运行状态。

### 3. SSH登录检查

```bash
ssh root@119.3.174.235

# 查看应用目录
ls -la /var/www/task-kanban/

# 查看Nginx状态
systemctl status nginx

# 查看版本
cat /var/www/task-kanban/.version
```

---

## 💰 成本估算（按需计费）

| 资源 | 规格 | 费用 |
|------|------|------|
| ECS | s6.large.2 (2核4G) | ¥0.16/小时 |
| 系统盘 | 40GB GPSSD | ¥0.02/小时 |
| 数据盘 | 40GB GPSSD | ¥0.02/小时 |
| 带宽 | 5Mbps BGP | ¥0.12/小时 |
| **合计** | - | **¥0.32/小时 ≈ ¥230/月** |

---

## 🔄 资源清理

### 自动清理（推荐）

```bash
cd 项目目录/terraform
terraform destroy -auto-approve
```

### 手动清理

```bash
# 删除ECS、EIP、安全组、子网、VPC
# 按顺序在华为云控制台删除
```

---

## 🛡️ 安全最佳实践

### 1. 密码安全

- ✅ 使用强密码（8-26位，含大小写+数字+特殊字符）
- ✅ 定期更换ECS密码
- ✅ 生产环境使用SSH密钥认证

### 2. 网络安全

- ✅ 安全组仅开放必要端口（22/80/443）
- ✅ 生产环境考虑使用VPC对等连接
- ✅ 配置HTTPS（使用Let's Encrypt证书）

### 3. CI/CD安全

- ✅ Secrets加密存储，不显示在日志中
- ✅ 配置分支保护规则
- ✅ PR必须通过CI检查才能合并

---

## ⚠️ 常见问题

### Q1: Terraform初始化超时

**原因**: GitHub网络问题导致Provider下载失败

**解决**: 使用华为云镜像或配置代理

### Q2: ECS创建失败

**原因**: 区域资源不足或规格不可用

**解决**: 切换到其他区域或调整规格

### Q3: SSH连接失败

**原因**: ECS未完全启动或密码错误

**解决**: 等待2-3分钟后重试，确认密码正确

### Q4: 应用无法访问

**原因**: Nginx配置错误或应用未构建

**解决**: 
```bash
ssh root@119.3.174.235
nginx -t  # 检查配置
systemctl status nginx  # 检查服务状态
ls -la /var/www/task-kanban/dist/  # 检查构建产物
```

### Q5: CI/CD部署失败

**原因**: GitHub Secrets未配置或配置错误

**解决**: 
1. 检查Actions日志
2. 确认Secrets配置正确
3. 手动触发工作流重试

---

## 📝 部署检查清单

### 部署前

- [ ] 已获取华为云AK/SK
- [ ] 已确定ECS登录密码
- [ ] 项目代码已推送到GitHub
- [ ] package.json存在且配置正确

### 部署中

- [ ] Terraform初始化成功
- [ ] 资源创建成功（9个资源）
- [ ] SSH可以连接ECS
- [ ] Node.js安装成功
- [ ] Nginx安装成功
- [ ] 应用构建成功

### 部署后

- [ ] 应用可以访问（HTTP 200）
- [ ] GitHub Secrets已配置
- [ ] CI/CD工作流运行成功
- [ ] 团队成员可以协作开发

---

## 📚 参考文档

- [Terraform华为云Provider文档](https://registry.terraform.io/providers/huaweicloud/huaweicloud/latest/docs)
- [GitHub Actions文档](https://docs.github.com/en/actions)
- [Nginx配置指南](https://nginx.org/en/docs/)
- [Vue部署最佳实践](https://vuejs.org/guide/best-practices/production-deployment.html)

---

## 🎯 快速部署命令汇总

```bash
# 1. 安装Terraform
# (使用Python脚本下载解压)

# 2. 初始化Terraform
cd 项目目录/terraform
terraform init

# 3. 部署资源
terraform apply -auto-approve

# 4. 部署应用
# (使用Python脚本SSH连接部署)

# 5. 配置CI/CD
git add .github/workflows/ci-cd.yml
git commit -m "Add CI/CD"
git push

# 6. 在GitHub配置Secrets
# (ECS_HOST, ECS_USER, ECS_PASSWORD)

# 完成！
```

---

## 📌 版本信息

- Terraform: 1.9.8
- 华为云Provider: 1.90.0
- Node.js: 18.x
- Nginx: 1.18+
- GitHub Actions: v4 (checkout, setup-node, upload-artifact, ssh-action)

---

**🎉 掌握此Skill，即可快速部署Vue应用到华为云ECS并配置完整的CI/CD流程！**
