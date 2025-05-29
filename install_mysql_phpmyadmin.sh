#!/bin/bash

# 脚本仅适用于 Debian 10/11/12+
set -e

echo "== 更新系统包 =="
apt update -y && apt upgrade -y

echo "== 安装 MySQL Server =="
apt install mysql-server -y
systemctl enable mysql
systemctl start mysql

echo "== 安装 PHP、Nginx、phpMyAdmin 所需组件 =="
apt install nginx php-fpm php-mysql php-mbstring php-zip php-gd php-json php-curl unzip wget -y

echo "== 安装 phpMyAdmin =="
apt install phpmyadmin -y

echo "== 创建 Nginx 配置文件（phpMyAdmin 映射路径） =="
cat > /etc/nginx/snippets/phpmyadmin.conf <<EOF
location /phpmyadmin {
    root /usr/share/;
    index index.php index.html index.htm;
    location ~ ^/phpmyadmin/(.+\.php)$ {
        try_files \$uri =404;
        root /usr/share/;
        fastcgi_pass unix:/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
        root /usr/share/;
    }
}
EOF

echo "== 应用到默认站点 =="
sed -i '/server {/a \\tinclude snippets/phpmyadmin.conf;' /etc/nginx/sites-available/default

echo "== 重启 Nginx 和 PHP =="
systemctl restart php7.4-fpm 2>/dev/null || systemctl restart php8.1-fpm 2>/dev/null || true
systemctl restart nginx

echo "== 完成！现在可以访问 phpMyAdmin 了：=="
ip=$(curl -s https://ipinfo.io/ip)
echo "🔗 http://$ip/phpmyadmin"
