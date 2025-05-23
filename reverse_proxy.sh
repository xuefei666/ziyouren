#!/bin/bash

set -e

# 检查并安装 nginx（兼容 Debian/Ubuntu 和 CentOS）
install_nginx() {
  if command -v nginx >/dev/null 2>&1; then
    echo "Nginx 已安装，跳过安装步骤。"
    return
  fi

  echo "正在安装 nginx..."

  if command -v apt >/dev/null 2>&1; then
    apt update
    apt install -y nginx
  elif command -v yum >/dev/null 2>&1; then
    yum install -y epel-release
    yum install -y nginx
  else
    echo "无法识别包管理器，请手动安装 nginx"
    exit 1
  fi
}

# 写入 nginx 配置文件
create_nginx_conf() {
  cat > /etc/nginx/sites-available/ip_proxy <<EOF
server {
    listen 8550 default_server;
    listen [::]:8550 default_server;
    server_name _;

    location / {
        proxy_pass https://jdsjk-js3dkd.zyrdns.cc;
        proxy_ssl_server_name on;
        proxy_set_header Host jdsjk-js3dkd.zyrdns.cc;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
  echo "Nginx 配置文件已写入 /etc/nginx/sites-available/ip_proxy"
}

# 启用配置（兼容 Debian/Ubuntu 和 CentOS）
enable_nginx_conf() {
  if [ -d /etc/nginx/sites-enabled ]; then
    ln -sf /etc/nginx/sites-available/ip_proxy /etc/nginx/sites-enabled/default
  else
    # CentOS 默认没有 sites-enabled，直接写入 nginx.conf
    grep -q "include /etc/nginx/sites-enabled/\*;" /etc/nginx/nginx.conf || \
      sed -i '/http {/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
    mkdir -p /etc/nginx/sites-enabled
    ln -sf /etc/nginx/sites-available/ip_proxy /etc/nginx/sites-enabled/default
  fi
  echo "Nginx 配置已启用"
}

# 测试并重载 nginx
reload_nginx() {
  if nginx -t; then
    systemctl reload nginx
    echo "✅ Nginx 反代已启用，监听端口 8550"
  else
    echo "❌ Nginx 配置测试失败，请检查配置"
    exit 1
  fi
}

# 主流程
install_nginx
create_nginx_conf
enable_nginx_conf
reload_nginx
