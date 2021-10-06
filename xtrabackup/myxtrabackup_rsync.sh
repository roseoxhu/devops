#!/bin/bash

##############################################
# 同步xtrabackup MySQL备份到深圳机房
##############################################

# 需要建立SSH免密码登录
target_user=xtrabacker
target_host=192.168.1.xxx
log_prefix=/data/logs/xtrabackup

src_dir=$1
if [[ "$src_dir" == "" ]]; then
    echo "Usage: $0 <src_dir>"
    exit 0
fi
target_dir=$(dirname $src_dir)

today=$(/bin/date '+%Y%m%d')
log_file=$log_prefix/rsync-$today.log
log_dir=$(dirname $log_file)
if [ ! -d $log_dir ]; then
    mkdir -p $log_dir
fi

echo "[$(date '+%F %T')] rsync start" >> $log_file
echo "[$(date '+%F %T')] time rsync -alv --progress $src_dir $target_user@$target_host:$target_dir/ >> $log_file 2>&1" >> $log_file
time rsync -alv --progress $src_dir $target_user@$target_host:$target_dir/ >> $log_file 2>&1
echo "[$(date '+%F %T')] rsync done." >> $log_file
