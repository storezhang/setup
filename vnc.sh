#!/bin/bash

password="$1"

# 安装
echo $password | sudo -S sudo apt update && sudo apt install x11vnc -y

# 设置密码
sudo x11vnc -storepasswd $password /etc/vnc/passwd.pass

# 创建服务
sudo tee /etc/systemd/system/vnc.service > /dev/null <<EOF
[Unit]
Description=Remote desktop service (VNC)
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
