#!/bin/bash

USERNAME=storezhang

# 取得Root权限
sudo -i

# 判断用户是否存在
if id "${USERNAME}" >/dev/null 2>&1; then
    echo "用户存在，继续执行"
else
    echo "用户不存在，添加用户，请输入用户信息"
    adduser --uid 1026 ${USERNAME}

    echo "将用户添加到Sudo组"
    usermod -aG sudo ${USERNAME}
fi


echo "更新源"
apt update
apt upgrade


echo "安装Docker"
apt install docker.io
usermod -aG docker ${USERNAME}

echo "写入镜像地址"
cat>/etc/docker/daemon.json<<EOF
{
        "registry-mirrors": [
                "https://docker.mirrors.ustc.edu.cn"
        ]
}
EOF


echo "完全删阶Snap"
snap remove $(snap list | awk '!/^Name|^core/ {print $1}')
umount /var/snap
systemctl stop snapd
apt remove --purge --assume-yes snapd gnome-software-plugin-snap
rm -rf ~/snap
rm -rf /snap
rm -rf /var/snap
rm -rf /var/lib/snapd


echo "增加计划任务"
echo "自动关机"
(crontab -l ; echo "") | crontab -
(crontab -l ; echo "# 自动关机") | crontab -
(crontab -l ; echo "59	00	*	*	*	/sbin/shutdown -h now") | crontab -

echo "自动更新系统"
(crontab -l ; echo "") | crontab -
(crontab -l ; echo "# 自动更新系统") | crontab -
(crontab -l ; echo "00	09	*	*	*	apt update -y && apt upgrade -y") | crontab -

echo "清理Docker日志"
(crontab -l ; echo "") | crontab -
(crontab -l ; echo "# 清理Docker日志") | crontab -
(crontab -l ; echo "30	09	*	*	1	docker ps | awk '{if (NR>1){print $1}}' | xargs docker inspect --format='{{.LogPath}}' | xargs truncate -s 0") | crontab -

echo "清理Docker"
(crontab -l ; echo "") | crontab -
(crontab -l ; echo "# 清理Docker") | crontab -
(crontab -l ; echo "30	08	*	*	*	docker system prune --all --force --volumes") | crontab -


echo "注销当前Shell，使配置生效"
logout
