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

    # 需要重启使docker命令立即生效
    NEED_LOGOUT=true
fi


echo "更新源"
apt update -y
apt upgrade -y


DOCKER_APP="docker.io"
if ! apt list | grep -q "${DOCKER_APP}"; then
  echo "安装Docker"
  apt install ${DOCKER_APP}
  usermod -aG docker ${USERNAME}

  echo "写入镜像地址"
  cat>/etc/docker/daemon.json<<EOF
  {
          "registry-mirrors": [
                  "https://docker.mirrors.ustc.edu.cn"
          ]
  }
EOF
fi


SNAP_APP="snapd"
if ! apt list | grep -q "${SNAP_APP}"; then
  echo "完全删除Snap"
  snap remove --purge "$(snap list | awk '!/^Name|^core/ {print $1}')"
  umount /var/snap
  systemctl stop snapd
  apt remove --purge --assume-yes ${SNAP_APP} gnome-software-plugin-snap
  rm -rf ~/snap
  rm -rf /snap
  rm -rf /var/snap
  rm -rf /var/lib/snapd
fi


echo "增加计划任务"

CRON_TASK="自动关机"
if ! $(crontab -l | grep -q "${CRON_TASK}"); then
  echo "添加任务${CRON_TASK}"
  (crontab -l ; echo "") | crontab -
  (crontab -l ; echo "# ${CRON_TASK}") | crontab -
  (crontab -l ; echo "59	00	*	*	*	/sbin/shutdown -h now") | crontab -
else
  echo "任务${CRON_TASK}已存在"
fi

CRON_TASK="自动更新系统"
if ! $(crontab -l | grep -q "${CRON_TASK}"); then
  echo "添加任务${CRON_TASK}"
  (crontab -l ; echo "") | crontab -
  (crontab -l ; echo "# ${CRON_TASK}") | crontab -
  (crontab -l ; echo "00	09	*	*	*	apt update -y && apt upgrade -y") | crontab -
else
  echo "任务${CRON_TASK}已存在"
fi

CRON_TASK="清理Docker日志"
if ! $(crontab -l | grep -q "${CRON_TASK}"); then
  echo "添加任务${CRON_TASK}"
  (crontab -l ; echo "") | crontab -
  (crontab -l ; echo "# ${CRON_TASK}") | crontab -
  (crontab -l ; echo "30	09	*	*	1	docker ps | awk '{if (NR>1){print $1}}' | xargs docker inspect --format='{{.LogPath}}' | xargs truncate -s 0") | crontab -
else
  echo "任务${CRON_TASK}已存在"
fi

CRON_TASK="清理Docker"
if ! $(crontab -l | grep -q "${CRON_TASK}"); then
  echo "添加任务${CRON_TASK}"
  (crontab -l ; echo "") | crontab -
  (crontab -l ; echo "# ${CRON_TASK}") | crontab -
  (crontab -l ; echo "30	08	*	*	*	docker system prune --all --force --volumes") | crontab -
else
  echo "任务${CRON_TASK}已存在"
fi


if [ "${NEED_LOGOUT}" = true ] ; then
  echo "注销当前Shell，使配置生效"
  logout
fi
