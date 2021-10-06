#!/bin/bash

###########################################################
# xtrabackup 定期备份MySQL数据库
# xtrabackup version 2.4.18 based on MySQL server 5.7.26
###########################################################

# 主从之间需要建立SSH免密码登录
# 以下参数根据实际配置修改
ssh_user=root
master_server=192.168.1.xxx
slaver_server=192.168.1.yyy
mysql_conf=/data/service/mysql/etc/my.cnf
mysql_socket=/data/service/mysql/run/mysql.sock
mysql_user=xtrabacker
mysql_pass='password-for-xtrabacker'


# 参数$1=项目名称,构成备份目录: foo, bar
project=$1
if [[ "$project" == "" ]]; then
    echo "Usage: $0 <project>"
    exit 0
fi
# 定义备份路径前缀
target_dir_prefix=/data/xtrabackup/$project

# 第一步创建备份目录
# 指定备份日期
today=$2
if [[ "$today" == "" ]]; then
    # 不指定备份日期，默认使用当前日期
    today=$(date '+%Y%m%d')
fi
target_dir="$target_dir_prefix/$today"

# create remote dir
echo "[$(date '+%F %T')] Create target dir @$slaver_server:$target_dir"
ssh $ssh_user@$slaver_server "mkdir -p $target_dir"

# shell中使用符号"$?"来表示上一条命令执行的返回值，如果为0则代表执行成功，其他表示失败
# [ -f /etc/hosts ] && echo "Found" || echo "Not found"
#if [ $? -eq 0 ]; then
if ssh $ssh_user@$slaver_server "test -d $target_dir"; then
    echo "[$(date '+%F %T')] @$slaver_server:$target_dir created successful."
else
    echo "[$(date '+%F %T')] @$slaver_server:$target_dir creation failed!"
    exit 0
fi

# 第二步开始备份
xtrabackup_options="--defaults-file=$mysql_conf --socket=$mysql_socket --user=$mysql_user --password=$mysql_pass"
xtrabackup_options="$xtrabackup_options --backup --compress --compress-threads=8 --stream=xbstream --parallel=8"
ssh_cmd="/usr/bin/xbstream -x -C $target_dir"

echo "[$(date '+%F %T')] xtrabackup start"
echo "[$(date '+%F %T')] time xtrabackup $xtrabackup_options | ssh $ssh_user@$slaver_server $ssh_cmd"
time xtrabackup $xtrabackup_options | ssh $ssh_user@$slaver_server $ssh_cmd
echo "[$(date '+%F %T')] xtrabackup done."

# 第三步同步备份到异地机房(确保带宽要够大)
# ssh远程后台执行脚本, 增加>/dev/null 2>&1, 本机即时退出
rsync_cmd="/root/bin/myxtrabackup_rsync.sh $target_dir"
echo "[$(date '+%F %T')] rsync start"
echo "[$(date '+%F %T')] time ssh $ssh_user@$slaver_server '$rsync_cmd >/dev/null 2>&1 &'"
time ssh $ssh_user@$slaver_server "$rsync_cmd >/dev/null 2>&1 &"
echo "[$(date '+%F %T')] rsync done."
