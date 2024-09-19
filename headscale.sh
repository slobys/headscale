#!/bin/bash
read -p "请输入服务器IP: " SERVER_IP
read -p "请输入Headscale端口: " HEADSCALE_PORT
read -p "请输入IP前缀（例如：100.64.0.0）: " IP_PREFIX
read -p "请输入Derp服务端口: " DERP_PORT

# 更新系统并安装依赖
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget unzip

# 重命名并安装Headscale
mv headscale_0.23.0_linux_amd64.deb headscale.deb
sudo dpkg -i headscale.deb

# 设置Headscale开机自启并启动
sudo systemctl enable headscale
sudo systemctl start headscale

# 安装Nginx
sudo apt install -y nginx

# 配置Nginx
sudo sed -i '/# Please see \/usr\/share\/doc\/nginx-doc\/examples\/ for more detailed examples./a \
##\n\
map $http_upgrade $connection_upgrade {\n\
    default keep-alive;\n\
    "websocket" upgrade;\n\
    "" close;\n\
}\n\
server {\n\
    listen '"$HEADSCALE_PORT"';\n\
    listen [::]:'"$HEADSCALE_PORT"';\n\
    server_name '"$SERVER_IP"';\n\
    location / {\n\
        proxy_pass http://127.0.0.1:8080;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Upgrade $http_upgrade;\n\
        proxy_set_header Connection $connection_upgrade;\n\
        proxy_set_header Host $host;\n\
        proxy_buffering off;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
        add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;\n\
    }\n\
    location /web {\n\
        index index.html;\n\
        alias /var/www/web;\n\
    }\n\
}\n\
server {\n\
    listen 80;\n\
    listen [::]:80;\n\
    server_name 127.0.0.1;\n\
    root /var/www;\n\
    index index.html index.htm index.nginx-debian.html;\n\
    location /d {\n\
        alias /var/www;\n\
        autoindex on;\n\
    }\n\
    location / {\n\
        try_files $uri $uri/ =404;\n\
    }\n\
}' /etc/nginx/sites-available/default

# 重启Nginx
sudo systemctl restart nginx

# 解压并安装Headscale UI
sudo unzip headscale-ui.zip -d /var/www

# 创建 derp.json 文件
sudo bash -c "cat > /var/www/derp.json << EOF
{
    \"Regions\": {
        \"900\": {
            \"RegionID\": 900,
            \"RegionCode\": \"myderp\",
            \"Nodes\": [
                {
                    \"Name\": \"a\",
                    \"RegionID\": 900,
                    \"DERPPort\": $DERP_PORT,
                    \"IPv4\": \"$SERVER_IP\",
                    \"InsecureForTests\": true
                }
            ]
        }
    }
}
EOF"

# 修改Headscale配置文件
sudo sed -i "s|^server_url:.*|server_url: http://$SERVER_IP:$HEADSCALE_PORT|" /etc/headscale/config.yaml
sudo sed -i "s|^\( *\)v4: 100.64.0.0/10|\1v4: $IP_PREFIX/24|" /etc/headscale/config.yaml
sudo sed -i "s|^\( *\)v6: fd7a:115c:a1e0::/48|#\1v6: fd7a:115c:a1e0::/48|" /etc/headscale/config.yaml
sudo sed -i "s|^\( *\)- https://controlplane.tailscale.com/derpmap/default|#\1- https://controlplane.tailscale.com/derpmap/default\n\1- http://127.0.0.1/d/derp.json|" /etc/headscale/config.yaml

# 重启服务
sudo systemctl restart headscale
sudo systemctl restart nginx

# 生成API密钥
headscale apikeys create --expiration 9999d

echo "安装完成！请使用生成的API密钥和以下链接登陆Headscale-ui面板："
echo "http://$SERVER_IP:$HEADSCALE_PORT/web"
echo "使用以下命令将设备连接到Headscale服务器："
echo "tailscale up --login-server=http://$SERVER_IP:$HEADSCALE_PORT"

