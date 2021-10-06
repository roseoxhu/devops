#!/bin/sh

###########################################################
# 系统管理员使用ansible 在远程服务器（组）上批量创建多个用户
###########################################################

# 需要事先安装 /usr/bin/ansible
# 并配置好远程服务器分组列表
if [ $# != 1 ] ; then
    echo "USAGE: $0 HOST_GROUP"
    exit 1;
fi
HOST_GROUP=$1

# 定义需要添加的用户
USERS=('chenjing' 'chuyang' 'houxiaoyi' 'maweiwei')

for USER in ${USERS[@]}; do
    echo -n "    ansible add $USER ";
    /root/bin/ansible_add_user.sh $HOST_GROUP $USER
done

unset USERS # 删除整个数组
