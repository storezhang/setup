#!/bin/bash

# 取得Root权限
echo "当前账号是：$(whoami)"
if [ "$UID" -eq 0 ]; then
    echo "已经是ROOT账号，继续执行"
else
    echo "正在升级成ROOT账号，请输入密码"
    exec sudo "$0" "$@"
fi

USERNAME=storezhang
NEED_LOGOUT=false

# 判断用户是否存在
USER_EXISTS=$(grep -c "^${USERNAME}:" /etc/passwd)
if [ "${USER_EXISTS}" -eq 0 ]; then
    echo "用户不存在，添加用户"
    adduser --uid 1026 ${USERNAME}

    echo "将用户添加到Sudo组"
    usermod -aG sudo ${USERNAME}
else
    echo "用户已存在，继续执行"
fi

echo "创建命令快捷方式"
PROFILE="/etc/profile"
SHORTCUT="升级系统"
if grep -q ${SHORTCUT} "${PROFILE}"; then
    echo "${SHORTCUT}快捷命令已存在"
else
    echo "增加${SHORTCUT}的快捷方式"
    cat <<EOF >> "${PROFILE}"

# ${SHORTCUT}
alias upgrade="sudo apt update -y && sudo apt upgrade -y"
EOF
fi

SHORTCUT="安装软件"
if grep -q ${SHORTCUT} "${PROFILE}"; then
    echo "${SHORTCUT}快捷命令已存在"
else
    echo "增加${SHORTCUT}的快捷方式"
    cat <<EOF >> "${PROFILE}"

# ${SHORTCUT}
alias install="sudo apt install -y"
EOF
fi

SHORTCUT="查看Docker日志"
if grep -q ${SHORTCUT} "${PROFILE}"; then
    echo "${SHORTCUT}快捷命令已存在"
else
    echo "增加${SHORTCUT}的快捷方式"
    cat <<EOF >> "${PROFILE}"

# ${SHORTCUT}
alias dl="sudo docker logs -f"
EOF
fi

SHORTCUT="连接Docker容器"
if grep -q ${SHORTCUT} "${PROFILE}"; then
    echo "${SHORTCUT}快捷命令已存在"
else
    echo "增加${SHORTCUT}的快捷方式"
    cat <<EOF >> "${PROFILE}"

# ${SHORTCUT}
alias di="di_script(){ sudo docker exec -it $1 /bin/bash; };di_script"
EOF
fi


echo "开始更新软件源"
DEBIAN_FRONTEND=noninteractive apt update -y -qq &> /dev/null
echo "软件源更新成功"

echo "开始升级系统"
DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq &> /dev/null
echo "系统升级成功"


# 安装NFS客户端
NFS_APP="nfs-common"
if dpkg -l | grep -qw ${NFS_APP}; then
    echo "系统已经安装NFS客户端，继续执行"
else
    apt install -y ${NFS_APP}
fi
# 安装SAMBA客户端
SAMBA_APP="cifs-utils"
if dpkg -l | grep -qw ${SAMBA_APP}; then
    echo "系统已经安装SAMBA客户端，继续执行"
else
    apt install -y ${SAMBA_APP}
fi


DOCKER_APP="docker.io"
if dpkg -l | grep -qw ${DOCKER_APP}; then
    echo "系统已经安装Docker，继续执行"
else
    echo "安装Docker"
    apt install -y ${DOCKER_APP}
    usermod -aG docker ${USERNAME}
    systemctl enable docker

    echo "写入镜像地址"
    cat>/etc/docker/daemon.json<<EOF
{
	"registry-mirrors": [
		"https://4lch7u25.mirror.aliyuncs.com",
		"https://docker.mirrors.ustc.edu.cn",
		"https://registry.docker-cn.com",
		"https://hub-mirror.c.163.com"
	]
}

EOF

    # 需要重启使docker命令立即生效
    NEED_LOGOUT=true
fi


SNAP_APP="snapd"
if dpkg -l | grep -qw ${SNAP_APP}; then
    echo "完全删除Snap"
    snap remove --purge "$(snap list | awk '!/^Name|^core/ {print $1}')"
    umount /var/snap
    systemctl stop snapd
    apt remove --purge --assume-yes -y ${SNAP_APP} gnome-software-plugin-snap
    rm -rf ~/snap
    rm -rf /snap
    rm -rf /var/snap
    rm -rf /var/lib/snapd

    # 清理包
    apt autoremove -y
else
    echo "系统没有安装Snap，不需要删除"
fi


echo "增加计划任务"
CRON_TASK="自动关机"
if crontab -l | grep -q "${CRON_TASK}"; then
    echo "任务${CRON_TASK}已存在"
else
    echo "添加任务${CRON_TASK}"
    (crontab -l ; echo "") | crontab -
    (crontab -l ; echo "# ${CRON_TASK}") | crontab -
    (crontab -l ; echo "59	00	*	*	*	/sbin/shutdown -h now") | crontab -
fi

CRON_TASK="自动更新系统"
if crontab -l | grep -q "${CRON_TASK}"; then
    echo "任务${CRON_TASK}已存在"
else
    echo "添加任务${CRON_TASK}"
    (crontab -l ; echo "") | crontab -
    (crontab -l ; echo "# ${CRON_TASK}") | crontab -
    (crontab -l ; echo "00	09	*	*	*	apt update -y && dpkg --configure -a && --apt upgrade -y") | crontab -
fi

CRON_TASK="自动清理系统"
if crontab -l | grep -q "${CRON_TASK}"; then
    echo "任务${CRON_TASK}已存在"
else
    echo "添加任务${CRON_TASK}"
    (crontab -l ; echo "") | crontab -
    (crontab -l ; echo "# ${CRON_TASK}") | crontab -
    (crontab -l ; echo "00	09	*	*	*	apt autoremove -y && apt purge -y") | crontab -
fi

CRON_TASK="自动启动启动失败的容器"
if crontab -l | grep -q "${CRON_TASK}"; then
    echo "任务${CRON_TASK}已存在"
else
    echo "添加任务${CRON_TASK}"
    (crontab -l ; echo "") | crontab -
    (crontab -l ; echo "# ${CRON_TASK}") | crontab -
    (crontab -l ; echo "*/1	*	*	*	*	docker start \$(docker ps --all --quiet --filter status=exited)") | crontab -
fi

CRON_TASK="清理Docker日志"
if crontab -l | grep -q "${CRON_TASK}"; then
    echo "任务${CRON_TASK}已存在"
else
    echo "添加任务${CRON_TASK}"
    (crontab -l ; echo "") | crontab -
    (crontab -l ; echo "# ${CRON_TASK}") | crontab -
    (crontab -l ; echo "30	09	*	*	1	docker ps | awk '{if (NR>1){print $1}}' | xargs docker inspect --format='{{.LogPath}}' | xargs truncate -s 0") | crontab -
fi

CRON_TASK="清理Docker所有容器和镜像以及卷"
if crontab -l | grep -q "${CRON_TASK}"; then
    echo "任务${CRON_TASK}已存在"
else
    echo "添加任务${CRON_TASK}"
    (crontab -l ; echo "") | crontab -
    (crontab -l ; echo "# ${CRON_TASK}") | crontab -
    (crontab -l ; echo "30	08	*	*	6	docker system prune --all --force --volumes") | crontab -
fi


echo "屏幕3分钟如无使用自动关闭"
blankingFile="/etc/systemd/system/enable-console-blanking.service"
if [ ! -f "${blankingFile}" ]; then
    touch "${blankingFile}"
    cat>"${blankingFile}"<<EOF
[Unit]
Description=Enable virtual console blanking

[Service]
Type=oneshot
Environment=TERM=linux
StandardOutput=tty
TTYPath=/dev/console
ExecStart=/usr/bin/setterm -blank 3

[Install]
WantedBy=multi-user.target

EOF

    chmod 664 "${blankingFile}"
    systemctl enable enable-console-blanking.service
fi


if [ "${NEED_LOGOUT}" = true ]; then
    echo "注销当前Shell，使配置生效"
    logout
fi
