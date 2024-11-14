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
sudo tee /etc/init/vnc.conf > /dev/null <<EOF
start on login-session-start

script 
x11vnc -display :0 -auth /var/run/lightdm/root/:0 -forever -bg -o /var/log/vnc.log -rfbauth /etc/vnc/passwd.pass -rfbport 5900 
end script
EOF

echo "服务文件写入完成！"
