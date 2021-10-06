#!/bin/sh

###########################################################
# 系统管理员使用ansible 修改远程服务器（组）DNS
###########################################################

# 需要事先安装 /usr/bin/ansible
# 并配置好远程服务器分组列表
if [ $# != 1 ] ; then
    echo "USAGE: $0 HOST_GROUP"
    exit 1;
fi
HOST_GROUP=$1

# 1)修改DNS 
# CentOS: /etc/sysconfig/network-scripts/ifcfg-eth0
# DNS1=211.167.230.100
# DNS2=211.167.230.200
ifcfg_ethx=/etc/sysconfig/network-scripts/ifcfg-eth0
MODULE_ARGS="path=$ifcfg_ethx after='DNS' regexp='211.167.230.100' replace='219.141.139.10'"
ansible $HOST_GROUP -m replace -a "$MODULE_ARGS"

MODULE_ARGS="path=$ifcfg_ethx after='DNS' regexp='211.167.230.200' replace='219.141.140.10'"
ansible $HOST_GROUP -m replace -a "$MODULE_ARGS"

# TODO Debian: /etc/network/interfaces

# 2)修改DNS /etc/resolv.conf
# nameserver 211.167.230.100
# nameserver 211.167.230.200
# https://docs.ansible.com/ansible/latest/modules/replace_module.html
MODULE_ARGS="path=/etc/resolv.conf after='nameserver' regexp='211.167.230.100' replace='219.141.139.10'"
ansible $HOST_GROUP -m replace -a "$MODULE_ARGS"

MODULE_ARGS="path=/etc/resolv.conf after='nameserver' regexp='211.167.230.200' replace='219.141.140.10'"
ansible $HOST_GROUP -m replace -a "$MODULE_ARGS"
