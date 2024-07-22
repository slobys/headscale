#!/bin/bash
# 获取用户输入的域名和端口
read -p "请输入域名: " DOMAIN
read -p "请输入Derp服务端口: " DERP_PORT
read -p "请输入HTTP端口: " HTTP_PORT
# 关闭防火墙功能
disable_firewall() {
    # 关闭ufw
    if command -v ufw > /dev/null 2>&1; then
        ufw disable
        echo "ufw 已关闭"
    fi
    # 关闭firewalld
    if command -v firewall-cmd > /dev/null 2>&1; then
        systemctl stop firewalld
        systemctl disable firewalld
        echo "firewalld 已关闭"
    fi
    # 关闭iptables
    if command -v iptables > /dev/null 2>&1; then
        iptables -F
        iptables -X
        iptables -t nat -F
        iptables -t nat -X
        iptables -t mangle -F
        iptables -t mangle -X
        iptables -t raw -F
        iptables -t raw -X
        echo "iptables 规则已清除"
    fi
}
# 关闭所有防火墙
disable_firewall
# 更新和升级软件包
apt update && apt upgrade -y
# 安装依赖包
apt install -y wget git openssl curl
# 下载并安装Go
GO_VERSION="go1.22.5"   #这个可以替换为最新的版本
rm -rf /usr/local/go && tar -C /usr/local -xzf ${GO_VERSION}.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
source /etc/profile
# 设置Go环境变量
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct
# 安装Derper服务器源码
go install tailscale.com/cmd/derper@main
DERPER_PATH=$(go env GOPATH)/pkg/mod/tailscale.com@*/cmd/derper
# 修改cert.go文件
CERT_GO_PATH=$(find ${DERPER_PATH} -type f -name "cert.go")
sed -i '/if hi.ServerName != m.hostname/,+2 s/^/\/\//' ${CERT_GO_PATH}
# 编译Derper服务器
cd ${DERPER_PATH}
go build -o /etc/derp/derper
# 返回到根目录
cd ~
# 生成自签名SSL证书
mkdir -p /etc/derp
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /etc/derp/${DOMAIN}.key -out /etc/derp/${DOMAIN}.crt -subj "/CN=${DOMAIN}" -addext "subjectAltName=DNS:${DOMAIN}"
# 创建systemd服务文件
cat > /etc/systemd/system/derp.service <<EOF
[Unit]
Description=TS Derper
After=network.target
Wants=network.target
[Service]
User=root
Restart=always
ExecStart=/etc/derp/derper -hostname ${DOMAIN} -a :${DERP_PORT} -http-port ${HTTP_PORT} -certmode manual -certdir /etc/derp
RestartPreventExitStatus=1
[Install]
WantedBy=multi-user.target
EOF
# 设置Derper服务开机启动并启动服务
systemctl enable derp
systemctl start derp
# 安装Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
# 重新加载systemd服务并重启Derper服务
systemctl daemon-reload
systemctl restart derp
echo "Tailscale和Derper服务器安装配置完成"
