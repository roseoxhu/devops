#!/bin/bash

###########################################################
# xtrabackup 定期备份MySQL数据库-增量备份
# xtrabackup version 2.4.18 based on MySQL server 5.7.26
# yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
# yum -y install percona-xtrabackup-24.x86_64
# yum -y install qpress.x86_64
###########################################################
# 周日全备，其他日期增备
# 日 一 二 三 四 五 六
# 0  1  2  3  4  5  6
###########################################################
#set -x

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
tmpdir=/data/xtrabackup/tmp/$project
target_dir_prefix=/data/xtrabackup/$project
# 使用xbstream+压缩备份后，无备份目录
# 但xtrabackup可指定--extra-lsndir目录，存放此次备份的xtrabackup_checkpoints文件；
# 后面增量备份时，--incremental-basedir指向前一日的extra-lsndir目录便可。
lsn_dir_prefix=/data/xtrabackup/lsn/$project

# 第一步创建备份目录
# 参数$2=备份日期
today=$2
if [[ "$today" == "" ]]; then
    # 不指定备份日期，默认使用当前日期
    today=$(date '+%Y%m%d')
fi
# 日期所属周几?
weekday=$(date -d "$today" +%w)
if [[ "$weekday" == "0" ]]; then
    baseday=$today
    target_dir="$target_dir_prefix/$baseday/base"
    lsn_dir="$lsn_dir_prefix/$baseday/base"
    last_lsn_dir=""
else
    baseday=$(date -d "$today $weekday days ago" '+%Y%m%d')
    target_dir="$target_dir_prefix/$baseday/inc$weekday"
    lsn_dir="$lsn_dir_prefix/$baseday/inc$weekday"

    # 上一个日期所属周几?
    last_weekday=$(expr $weekday - 1)
    if [[ "$last_weekday" == "0" ]]; then
        last_lsn_dir="$lsn_dir_prefix/$baseday/base"
    else
        last_lsn_dir="$lsn_dir_prefix/$baseday/inc$last_weekday"
    fi
    # 检查上次备份检查点文件
    if [ ! -f $last_lsn_dir/xtrabackup_checkpoints ]; then
        echo "[$(date '+%F %T')] 上次备份检查点文件不存在: $last_lsn_dir/xtrabackup_checkpoints"
	exit 1
    fi
fi
# 检查当前日期备份检查点文件
if [ -f $lsn_dir/xtrabackup_checkpoints ]; then
    echo "[$(date '+%F %T')] 当前日期备份检查点文件已存在: $lsn_dir/xtrabackup_checkpoints"
    exit 1
fi

# create local dir
for dir in $tmpdir $target_dir_prefix $lsn_dir_prefix $lsn_dir
do
    if [ ! -d $dir ]; then
        echo "[$(date '+%F %T')] Create local dir @$master_server:$dir"
        mkdir -pv $dir
    fi
done

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
xtrabackup_options="$xtrabackup_options --extra-lsndir=$lsn_dir"
if [ -n "$last_lsn_dir" ]; then
    # 增备的基础目录
    xtrabackup_options="$xtrabackup_options --incremental-basedir=$last_lsn_dir" 
fi
xtrabackup_options="$xtrabackup_options --target-dir=$target_dir_prefix --tmpdir=$tmpdir"
ssh_cmd="/usr/bin/xbstream -x -C $target_dir"

echo
echo "[$(date '+%F %T')] xtrabackup start"
echo "[$(date '+%F %T')] time xtrabackup $xtrabackup_options | ssh $ssh_user@$slaver_server $ssh_cmd"
time xtrabackup $xtrabackup_options | ssh $ssh_user@$slaver_server $ssh_cmd
#if [ $? -eq 0 ]; then
#    echo "[$(date '+%F %T')] 备份成功"
#fi
echo "[$(date '+%F %T')] xtrabackup done."

# 第三步同步备份到异地机房(确保带宽要够大)
# ssh远程后台执行脚本,增加>/dev/null 2>&1,本机即时退出
rsync_cmd="/root/bin/myxtrabackup_rsync.sh $target_dir"
echo 
echo "[$(date '+%F %T')] rsync start"
echo "[$(date '+%F %T')] time ssh $ssh_user@$slaver_server '$rsync_cmd >/dev/null 2>&1 &'"
time ssh $ssh_user@$slaver_server "$rsync_cmd >/dev/null 2>&1 &"
echo "[$(date '+%F %T')] rsync done."
