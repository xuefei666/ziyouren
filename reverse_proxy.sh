#!/bin/bash

# 安装 nginx（如未安装）
if ! command -v nginx >/dev/null 2>&1; then
  echo "正在安装 nginx..."
  apt update && apt install -y nginx
fi

# 创建配置文件
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

# 启用配置
ln -sf /etc/nginx/sites-available/ip_proxy /etc/nginx/sites-enabled/default

# 测试配置并重载
nginx -t && systemctl reload nginx && echo "✅ Nginx 反代已启用" || echo "❌ 配置出错，请检查"
