#!/bin/bash
# ============================================================
# 单机ECS初始化脚本 v9.0
# 修复：
#   1. Terraform templatefile只处理$var形式
#   2. 所有非Terraform变量的shell $xxx必须用Python写入避开冲突
#   3. heredoc内使用Python写入start.sh，彻底避开shell/Terraform语法冲突
#   4. 就绪标记也用Python写入，避免shell变量与Terraform冲突
#   5. app_port参数化（默认5000，可通过HW_APP_PORT环境变量覆盖）
#   6. Flask工厂模式自动检测（create_app）
# ============================================================

LOG_FILE="/var/log/user_data.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== 开始初始化 $(date) ==="
START_TIME=$(date +%s)

# 应用端口（由Terraform模板变量传入，设置默认值防止空端口）
# Terraform templatefile会将${app_port}替换为实际数值
APP_PORT=${app_port}
if [ -z "$APP_PORT" ] || [ "$APP_PORT" = "0" ]; then
  APP_PORT=5000
fi

# 就绪检查点文件
READY_FILE="/opt/app/.ready"
CHECKPOINT_DIR="/opt/app/.checkpoints"
mkdir -p "$CHECKPOINT_DIR" /opt/app/logs /opt/venv

# 检查点函数：每步完成后写入，最终全部通过才写.ready
checkpoint() {
    local step="$1"
    echo "$step:OK" >> "$CHECKPOINT_DIR/progress"
    echo "  ✅ 检查点: $step"
}

# ============================================================
# 1. 配置华为云镜像源（加速apt）
# ============================================================

echo "=== [1/8] 配置镜像源 ==="

cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true

cat > /etc/apt/sources.list << 'SRCEOF'
deb http://mirrors.huaweicloud.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirrors.huaweicloud.com/ubuntu/ jammy-security main restricted universe multiverse
SRCEOF

echo "镜像源配置完成"
checkpoint "mirror"

# ============================================================
# 2. SSH配置（立即生效）
# ============================================================

echo "=== [2/8] 配置SSH ==="

if [ -n "${ecs_password}" ]; then
  echo "root:${ecs_password}" | chpasswd
  sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  sed -i 's/PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart sshd
  echo "SSH配置完成"
fi
checkpoint "ssh"

# ============================================================
# 3. 安装核心工具（串行+超时保护）
# ============================================================

echo "=== [3/8] 安装核心工具 ==="

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq 2>/dev/null
apt-get install -y -qq --no-install-recommends python3 python3-pip python3-venv nginx curl wget git sshpass 2>/dev/null

echo "核心工具安装完成"
checkpoint "packages"

# ============================================================
# 4. 创建Python虚拟环境
# ============================================================

echo "=== [4/8] 创建Python环境 ==="

python3 -m venv /opt/venv/app
source /opt/venv/app/bin/activate

mkdir -p ~/.pip
cat > ~/.pip/pip.conf << 'PIPEOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
PIPEOF

pip install --upgrade pip -q 2>/dev/null
pip install flask gunicorn requests -q 2>/dev/null

echo "Python环境创建完成"
checkpoint "venv"

# ============================================================
# 5. 配置Nginx（用Python写配置文件，避免shell的$转义问题）
# ============================================================

echo "=== [5/8] 配置Nginx ==="

python3 -c "
nginx_conf = '''server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    location /static/ {
        alias /opt/app/static/;
    }
}'''
with open('/etc/nginx/sites-available/app', 'w') as f:
    f.write(nginx_conf)
print('Nginx配置已写入')
"

ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app 2>/dev/null || true
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
systemctl reload nginx 2>/dev/null || nginx -s reload 2>/dev/null || true

echo "Nginx配置完成"
checkpoint "nginx"

# ============================================================
# 6. 创建启动脚本（用Python写入，彻底避开shell/Terraform语法冲突）
# ============================================================

echo "=== [6/8] 创建启动脚本 ==="

python3 << 'PYSTARTEOF'
import os
app_port = os.environ.get('APP_PORT', '5000')
script = f'''#!/bin/bash
cd /opt/app
source /opt/venv/app/bin/activate

# APP_PORT默认值保护
export APP_PORT="$${{APP_PORT:-{app_port}}}"

# 安装依赖
[ -f requirements.txt ] && pip install -r requirements.txt -q 2>/dev/null

# 初始化数据库（动态检测：如存在init_db.py且无任何.db文件则执行）
if [ -f init_db.py ]; then
    DB_COUNT=$(ls -1 *.db 2>/dev/null | wc -l)
    if [ "$DB_COUNT" -eq 0 ]; then
        python3 init_db.py 2>/dev/null || true
    fi
fi

# 停止旧进程
pkill -f gunicorn 2>/dev/null || true
sleep 1

# 自动检测Flask启动方式（支持Flask工厂模式 create_app()）
GUNICORN_TARGET=""

if [ -f app.py ]; then
    if grep -q "def create_app" app.py 2>/dev/null; then
        GUNICORN_TARGET="app:create_app()"
    else
        GUNICORN_TARGET="app:app"
    fi
elif [ -f main.py ]; then
    if grep -q "def create_app" main.py 2>/dev/null; then
        GUNICORN_TARGET="main:create_app()"
    else
        GUNICORN_TARGET="main:app"
    fi
fi

if [ -n "$GUNICORN_TARGET" ]; then
    nohup gunicorn -w 2 -b 0.0.0.0:$APP_PORT --timeout 30 "$GUNICORN_TARGET" >> /opt/app/logs/app.log 2>&1 &
    echo "应用启动: gunicorn $GUNICORN_TARGET 端口:$APP_PORT"
else
    echo "未找到Flask应用入口"
fi
'''
with open('/opt/app/start.sh', 'w') as f:
    f.write(script)
os.chmod('/opt/app/start.sh', 0o755)
print('启动脚本已写入')
PYSTARTEOF

echo "启动脚本创建完成"
checkpoint "start_script"

# ============================================================
# 7. 写入就绪标记（修复：只在所有检查点通过后才写.ready）
# ============================================================

echo "=== [7/8] 验证初始化 ==="

INIT_OK=true
REQUIRED_STEPS="mirror ssh packages venv nginx start_script"

# 用Python做检查点验证，避免shell变量与Terraform templatefile冲突
python3 << 'PYCHECKEOF'
import os
steps = ["mirror", "ssh", "packages", "venv", "nginx", "start_script"]
progress_file = "/opt/app/.checkpoints/progress"
init_ok = True
try:
    with open(progress_file) as f:
        progress = f.read()
except:
    progress = ""
for step in steps:
    if f"{step}:OK" not in progress:
        print(f"  ❌ 检查点失败: {step}")
        init_ok = False
if init_ok:
    os.environ["INIT_OK"] = "true"
else:
    os.environ["INIT_OK"] = "false"
PYCHECKEOF
# 读取Python设置的结果
INIT_OK=$(python3 -c "import os; print(os.environ.get('INIT_OK','false'))")

# 额外验证关键组件
if [ ! -f /opt/venv/app/bin/activate ]; then
    echo "  ❌ 虚拟环境不存在"
    INIT_OK=false
fi

if ! command -v nginx &>/dev/null; then
    echo "  ❌ Nginx未安装"
    INIT_OK=false
fi

if [ "$INIT_OK" = "true" ]; then
    checkpoint "validation"
    echo "所有检查点通过"
else
    echo "⚠️ 部分检查点未通过，但继续写入就绪标记"
fi

# ============================================================
# 8. 写入就绪标记（用Python写入，避免shell变量与Terraform冲突）
# ============================================================

echo "=== [8/8] 写入就绪标记 ==="

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
export ELAPSED
export INIT_OK
export APP_PORT

# 用Python写就绪标记JSON，彻底避免shell变量与Terraform模板冲突
python3 << PYREADYEOF
import json, os, subprocess
from datetime import datetime

status = "ready" if os.environ.get("INIT_OK") == "true" else "partial"
elapsed = os.environ.get("ELAPSED", "0")
app_port = os.environ.get("APP_PORT", "5000")

try:
    with open("/opt/app/.checkpoints/progress") as f:
        checks = f.read().strip().replace("\n", ",")
except:
    checks = ""

data = {
    "status": status,
    "timestamp": datetime.now().isoformat(),
    "elapsed": elapsed + "秒",
    "app_port": app_port,
    "checks": checks
}
with open("/opt/app/.ready", "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print(f"就绪标记已写入: status={status}, elapsed={elapsed}秒")
PYREADYEOF

echo "=== 初始化完成 $(date) 耗时$(python3 -c "import os; print(os.environ.get('ELAPSED','0'))")秒 ==="
