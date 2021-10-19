#!/bin/bash

USERNAME=storezhang
NEED_LOGOUT=false

# 取得Root权限
sudo -i

# 判断用户是否存在
if id "${USERNAME}" >/dev/null 2>&1; then
    echo "用户已存在，继续执行"
else
    echo "用户不存在，添加用户，请输入用户信息"
    adduser --uid 1026 ${USERNAME}

    echo "将用户添加到Sudo组"
    usermod -aG sudo ${USERNAME}
fi


echo "更新软件源"
apt update -y
apt upgrade -y


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
		"https://docker.mirrors.ustc.edu.cn"
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
  (crontab -l ; echo "00	09	*	*	*	apt update -y && apt upgrade -y") | crontab -
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


if [ "${NEED_LOGOUT}" = true ] ; then
  echo "注销当前Shell，使配置生效"
  logout
fi
