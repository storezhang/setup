#!/bin/bash

password="123456"  # 这里请改成你自己登录账号的密码就可以，下方内容都不用变

# Step 1: 安装x11vnc
echo $password | sudo -S sudo apt update && sudo apt install x11vnc -y

# Step 2: 设置x11vnc密码
sudo x11vnc -storepasswd $password /etc/x11vnc.pass

# Step 3: 创建服务
sudo tee /etc/systemd/system/x11vnc.service > /dev/null <<EOF
[Unit]
Description=Remote desktop service (VNC)
Requires=display-manager.service
After=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -rfbauth /etc/x11vnc.pass -rfbport 5900 -shared
ExecStop=/usr/bin/killall x11vnc

[Install]
WantedBy=multi-user.target
EOF

echo "服务文件写入完成！"
# 刷新服务配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start x11vnc

# 设置服务为自启动
sudo systemctl enable x11vnc
echo "服务启动设置成功！"
