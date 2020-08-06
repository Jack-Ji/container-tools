#!/bin/bash

set -e

ME=$(whoami)
if [ $ME != "root" ]; then
	echo "please run script as root"
	exit 1
fi

if [ $# -ne 2 ]; then
	echo "usage: ./k8s-master.sh <advertise-ip> <pod-network-cidr>"
	exit 1
fi

if ! which kubeadm >/dev/null; then
	echo "please run ./k8s-bootstrap.sh first"
	exit 1
fi

if systemctl is-active kubelet >/dev/null; then
       	echo "kubernetes already active!"
	exit 1
fi

kubeadm init --apiserver-advertise-address=$1 --pod-network-cidr=$2
