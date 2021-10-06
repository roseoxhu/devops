#!/bin/sh

###########################################################
# 系统管理员使用ansible 在远程服务器（组）上创建用户
# 省去手工创建步骤的麻烦，然后用户通过SSH密钥登录
###########################################################

# 需要事先安装 /usr/bin/ansible
# 并配置好远程服务器分组列表
if [ $# != 2 ] ; then
    echo "USAGE: $0 HOST_GROUP USER_NAME"
    exit 1;
fi
HOST_GROUP=$1
USER_NAME=$2

# 添加用户
# https://docs.ansible.com/ansible/latest/modules/user_module.html#user-module
ansible $HOST_GROUP -m user -a "name=$USER_NAME shell=/bin/bash home=/home/$USER_NAME/ state=present"
echo "[$(date '+%F %T')] Added $USER_NAME"

# 收集所有远程主机的公钥
IP_FILE=/etc/ansible/$HOST_GROUP-ip.txt
if [ -e $IP_FILE ]; then
    ssh-keyscan -f $IP_FILE | grep ssh-rsa >> /home/$USER_NAME/.ssh/known_hosts
fi

# 批量上传公钥到服务器
# https://docs.ansible.com/ansible/latest/modules/authorized_key_module.html#authorized-key-module
# 
# ll /etc/ansible/roles/
#-rw-r--r--. 1 root root 414 Oct 16 19:23 id_rsa-chenjing.pub
#-rw-r--r--. 1 root root 387 Oct 16 15:17 id_rsa-chuyang.pub
#-rw-r--r--. 1 root root 764 Oct 16 15:17 id_rsa-houxiaoyi.pub
#-rw-r--r--. 1 root root 395 Oct 16 19:51 id_rsa-huzhiping.pub
#-rw-r--r--. 1 root root 743 Oct 16 15:17 id_rsa-maweiwei.pub
PUBKEY_FILE=/etc/ansible/roles/id_rsa-$USER_NAME.pub
ansible $HOST_GROUP -m authorized_key -a "user=$USER_NAME key='{{ lookup('file', '$PUBKEY_FILE')}}'"
echo "[$(date '+%F %T')] Authorized key for $USER_NAME"