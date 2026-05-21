# ============================================================
# 单机ECS部署方案 (Mode: single-ecs)
# 适用场景：小型应用、测试环境、个人项目
# 月费用：¥421.75 (2核4G + 40GB系统盘 + 100GB数据盘 + 5Mbps带宽)
# 资源数量：7个（VPC、子网、安全组、安全组规则x3、EIP、ECS）
# ============================================================

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
  region       = var.region
  access_key   = var.access_key
  secret_key   = var.secret_key
  project_id   = var.project_id != "" ? var.project_id : null
  project_name = var.project_id != "" ? null : var.region
}

# ============================================================
# 本地变量：统一标签
# ============================================================

locals {
  base_tags = {
    project     = var.project_name
    deploy_mode = "single-ecs"
    environment = var.environment
    managed_by  = "terraform"
    created_by  = var.created_by
  }
  merged_tags = merge(local.base_tags, var.common_tags)
}

# ============================================================
# 数据源
# ============================================================

data "huaweicloud_availability_zones" "available" {}

data "huaweicloud_compute_flavors" "available" {
  availability_zone = data.huaweicloud_availability_zones.available.names[0]
  performance_type  = "normal"
  cpu_core_count    = var.ecs_vcpu
  memory_size       = var.ecs_memory
}

data "huaweicloud_images_image" "ubuntu" {
  name        = "Ubuntu 22.04 server 64bit"
  most_recent = true
}

# ============================================================
# VPC（单机模式专用，简化版）
# ============================================================

resource "huaweicloud_vpc" "main" {
  count = var.reuse_vpc ? 0 : 1
  name  = "${var.project_name}-vpc"
  cidr  = var.vpc_cidr
  tags  = local.merged_tags
}

# ============================================================
# 子网（单机模式只需1个子网）
# ============================================================

resource "huaweicloud_vpc_subnet" "main" {
  count             = var.reuse_subnet ? 0 : 1
  name              = "${var.project_name}-subnet"
  vpc_id            = var.reuse_vpc ? var.existing_vpc_id : huaweicloud_vpc.main[0].id
  cidr              = var.subnet_cidr
  gateway_ip        = cidrhost(var.subnet_cidr, 1)
  primary_dns       = var.primary_dns
  secondary_dns     = var.secondary_dns
  availability_zone = data.huaweicloud_availability_zones.available.names[0]
  tags              = local.merged_tags
}

# ============================================================
# 安全组（单机模式专用，简化版）
# ============================================================

resource "huaweicloud_networking_secgroup" "main" {
  count       = var.reuse_security_group ? 0 : 1
  name        = "${var.project_name}-sg"
  description = "单机ECS安全组"
  tags        = local.merged_tags
}

# HTTP入口规则
resource "huaweicloud_networking_secgroup_rule" "http" {
  count             = var.reuse_security_group ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main[0].id
}

# HTTPS入口规则
resource "huaweicloud_networking_secgroup_rule" "https" {
  count             = var.reuse_security_group ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main[0].id
}

# SSH入口规则（可选）
resource "huaweicloud_networking_secgroup_rule" "ssh" {
  count             = var.reuse_security_group || !var.enable_ssh ? 0 : 1
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main[0].id
}

# 应用端口入口规则（app_port，默认5000）
resource "huaweicloud_networking_secgroup_rule" "app_port" {
  count             = var.reuse_security_group ? 0 : (var.app_port == 80 || var.app_port == 443 || var.app_port == 22 ? 0 : 1)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = var.app_port
  port_range_max    = var.app_port
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main[0].id
}

# ============================================================
# SSH密钥对（可选）
# ============================================================

resource "huaweicloud_compute_keypair" "deploy" {
  count      = var.ssh_public_key != "" ? 1 : 0
  name       = "${var.project_name}-key"
  public_key = var.ssh_public_key
}

# ============================================================
# EIP弹性公网IP
# ============================================================

resource "huaweicloud_vpc_eip" "web" {
  count = var.reuse_eip ? 0 : 1
  publicip {
    type = var.eip_type
  }
  bandwidth {
    name        = "${var.project_name}-bandwidth"
    size        = var.eip_bandwidth
    share_type  = "PER"
    charge_mode = var.eip_charge_mode
  }
  tags = local.merged_tags
}

# ============================================================
# ECS实例
# ============================================================

resource "huaweicloud_compute_instance" "web" {
  name               = "${var.project_name}-ecs"
  image_id           = data.huaweicloud_images_image.ubuntu.id
  flavor_id          = data.huaweicloud_compute_flavors.available.flavors[0].id
  availability_zone  = data.huaweicloud_availability_zones.available.names[0]
  security_group_ids = [var.reuse_security_group ? var.existing_security_group_id : huaweicloud_networking_secgroup.main[0].id]
  
  network {
    uuid = var.reuse_subnet ? var.existing_subnet_id : huaweicloud_vpc_subnet.main[0].id
  }
  
  system_disk_type = var.disk_type
  system_disk_size = var.system_disk_size
  
  data_disks {
    type                  = var.disk_type
    size                  = var.data_disk_size
    delete_on_termination = true
  }
  
  key_pair = var.ecs_password == "" && var.ssh_public_key != "" ? huaweicloud_compute_keypair.deploy[0].name : null
  
  # 修复：同时使用admin_pass设置密码，确保ECS创建后即可用密码登录
  # 不再仅依赖user_data中的chpasswd（异步执行可能导致SSH连接时密码未生效）
  admin_pass = var.ecs_password != "" ? var.ecs_password : null
  
  user_data = base64encode(templatefile("${path.module}/user_data_single.sh", {
    ecs_password = var.ecs_password
    app_port     = var.app_port
  }))
  
  tags = local.merged_tags
}

# ============================================================
# EIP绑定到ECS
# ============================================================

resource "huaweicloud_compute_eip_associate" "web" {
  count       = var.reuse_eip ? 0 : 1
  public_ip   = var.reuse_eip ? var.existing_eip_address : huaweicloud_vpc_eip.web[0].address
  instance_id = huaweicloud_compute_instance.web.id
}

# ============================================================
# 输出
# ============================================================

output "vpc_id" {
  value = var.reuse_vpc ? var.existing_vpc_id : huaweicloud_vpc.main[0].id
}

output "subnet_id" {
  value = var.reuse_subnet ? var.existing_subnet_id : huaweicloud_vpc_subnet.main[0].id
}

output "security_group_id" {
  value = var.reuse_security_group ? var.existing_security_group_id : huaweicloud_networking_secgroup.main[0].id
}

output "eip_id" {
  value = var.reuse_eip ? null : huaweicloud_vpc_eip.web[0].id
}

output "eip_address" {
  value = var.reuse_eip ? var.existing_eip_address : huaweicloud_vpc_eip.web[0].address
}

output "ecs_id" {
  value = huaweicloud_compute_instance.web.id
}

output "ecs_name" {
  value = huaweicloud_compute_instance.web.name
}

output "ecs_private_ip" {
  value = huaweicloud_compute_instance.web.access_ip_v4
}

output "system_disk_id" {
  value = huaweicloud_compute_instance.web.system_disk_id
}

output "data_disk_id" {
  value = var.data_disk_size > 0 ? "will_be_created" : null
}

output "access_url" {
  value = "http://${var.reuse_eip ? var.existing_eip_address : huaweicloud_vpc_eip.web[0].address}"
}

output "ssh_command" {
  value = "ssh root@${var.reuse_eip ? var.existing_eip_address : huaweicloud_vpc_eip.web[0].address}"
}

# ============================================================
# 变量定义（单机ECS专用）
# ============================================================

# 必填变量（用户输入）

variable "access_key" {
  description = "华为云Access Key ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "secret_key" {
  description = "华为云Secret Access Key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ecs_password" {
  description = "ECS登录密码（8-26位，含大小写字母+数字+特殊字符）"
  type        = string
  default     = ""
  sensitive   = true
}

# 基础配置变量

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_id" {
  description = "华为云项目ID（可选，为空时自动获取默认项目）"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "项目名称"
  type        = string
  default     = "my-app"
}

variable "environment" {
  description = "环境标识"
  type        = string
  default     = "dev"
}

variable "created_by" {
  description = "创建者"
  type        = string
  default     = "terraform"
}

variable "common_tags" {
  description = "通用标签"
  type        = map(string)
  default     = {}
}

# ECS配置变量

variable "ecs_vcpu" {
  description = "ECS CPU核数"
  type        = number
  default     = 2
}

variable "ecs_memory" {
  description = "ECS内存大小（GB）"
  type        = number
  default     = 4
}

variable "enable_ssh" {
  description = "是否开放SSH端口"
  type        = bool
  default     = true
}

variable "ssh_public_key" {
  description = "SSH公钥（可选，使用密钥登录）"
  type        = string
  default     = ""
}

# 网络配置变量

variable "vpc_cidr" {
  description = "VPC网段"
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnet_cidr" {
  description = "子网网段"
  type        = string
  default     = "192.168.1.0/24"
}

variable "primary_dns" {
  description = "主DNS服务器"
  type        = string
  default     = "100.125.1.250"
}

variable "secondary_dns" {
  description = "备DNS服务器"
  type        = string
  default     = "100.125.21.250"
}

# EIP配置变量

variable "eip_type" {
  description = "EIP类型"
  type        = string
  default     = "5_bgp"
}

variable "eip_bandwidth" {
  description = "EIP带宽大小（Mbps）"
  type        = number
  default     = 5
}

variable "eip_charge_mode" {
  description = "EIP计费模式"
  type        = string
  default     = "bandwidth"
}

# 磁盘配置变量

variable "disk_type" {
  description = "磁盘类型"
  type        = string
  default     = "GPSSD"
}

variable "system_disk_size" {
  description = "系统盘大小（GB）"
  type        = number
  default     = 40
}

variable "data_disk_size" {
  description = "数据盘大小（GB）"
  type        = number
  default     = 100
}

# 应用配置变量

variable "app_port" {
  description = "应用端口"
  type        = number
  default     = 5000
}

# 资源复用变量（可选）

variable "reuse_vpc" {
  description = "是否复用已有VPC"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "已有VPC ID"
  type        = string
  default     = ""
}

variable "reuse_subnet" {
  description = "是否复用已有子网"
  type        = bool
  default     = false
}

variable "existing_subnet_id" {
  description = "已有子网ID"
  type        = string
  default     = ""
}

variable "reuse_security_group" {
  description = "是否复用已有安全组"
  type        = bool
  default     = false
}

variable "existing_security_group_id" {
  description = "已有安全组ID"
  type        = string
  default     = ""
}

variable "reuse_eip" {
  description = "是否复用已有EIP"
  type        = bool
  default     = false
}

variable "existing_eip_address" {
  description = "已有EIP地址"
  type        = string
  default     = ""
}
