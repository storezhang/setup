#!/bin/bash

password="$1"

# 取得Root权限
echo "当前账号是：$(whoami)"
if [ "$EUID" -eq 0 ]; then
    echo "已经是ROOT账号，继续执行"
else
    echo "正在升级成ROOT账号，请输入密码"
    exec sudo "$0" "$@"
fi

# 安装
echo $password | sudo -S sudo apt update && sudo apt install x11vnc -y

# 设置密码
sudo mkdir -p /etc/vnc
sudo x11vnc -storepasswd $password /etc/vnc/passwd.pass

# 创建服务
sudo tee /etc/systemd/system/vnc.service > /dev/null <<EOF
[Unit]
Description=VNC
Requires=display-manager.service
After=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -rfbauth /etc/vnc/passwd.pass -rfbport 5900 -shared
ExecStop=/usr/bin/killall x11vnc

[Install]
WantedBy=multi-user.target
EOF

echo "服务文件写入完成！"
# 刷新服务配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start vnc

# 设置服务为自启动
sudo systemctl enable vnc
echo "服务启动设置成功！"
