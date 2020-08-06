#!/bin/bash

set -e

##################################### STEP 0 #####################################
# 参数及执行环境检查
##################################################################################
ME=$(whoami)
if [ $ME != "root" ]; then
	echo "please run script as root"
	exit 1
fi

if ! cat /etc/issue | grep -q 'Ubuntu 20\.04'; then
	echo "only support Ubuntu 20.04 distribution"
	exit 1
fi

if systemctl is-active kubelet >/dev/null; then
       	echo "kubernetes already active!"
	exit 1
fi

##################################### STEP 1 #####################################
# 基础工具下载安装及配置
##################################################################################
echo -e "\033[32m >>> 基础工具下载安装及配置... \033[0m"
cat <<EOF >/etc/apt/sources.list
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF

rm -f apt-key.gpg
wget https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg
apt-key add apt-key.gpg
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

apt update
apt install -y htop curl docker.io kubelet kubeadm kubectl

systemctl enable docker.service
if [ ! -e /etc/docker/daemon.json ]; then
	mkdir -p /etc/docker
	tee /etc/docker/daemon.json <<-'EOF'
	{
	  "registry-mirrors": ["https://schwx5hq.mirror.aliyuncs.com"],
	  "exec-opts": ["native.cgroupdriver=systemd"]
	}
	EOF
	systemctl daemon-reload
	systemctl restart docker
fi

##################################### STEP 3 #####################################
# 系统参数设置
##################################################################################
echo -e "\033[32m >>> 系统参数设置... \033[0m"
if ! lsmod | grep -q br_netfilter; then
	modprobe br_netfilter
fi
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
swapoff -a

##################################### STEP 4 #####################################
# 核心组件镜像下载
##################################################################################
echo -e "\033[32m >>> 核心组件镜像下载... \033[0m"
for m in $(kubeadm config images list 2>/dev/null); do
	ORIG=$m
	MIRRORED=$(echo $ORIG | sed 's#/#_#')
	if docker image inspect $ORIG >/dev/null; then
		echo -e "\033[32m     忽略已下载项 ${ORIG} \033[0m"
	else
		echo -e "\033[32m     开始下载 ${ORIG} \033[0m"
		docker pull "gcrxio/$MIRRORED"
		docker tag "gcrxio/$MIRRORED" $ORIG
	fi
done
echo -e "\033[32m     下载完毕! \033[0m"
docker image ls | grep -v "gcrxio"

