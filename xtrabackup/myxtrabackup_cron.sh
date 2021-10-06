#!/bin/bash

###########################################################
# xtrabackup 定期备份MySQL数据库
# 每天凌晨03:40执行
# 40 3 * * * /root/bin/myxtrabackup_cron.sh
# 每周日凌晨03:40执行
# 40 3 * * 0 /root/bin/myxtrabackup_cron.sh
###########################################################
#set -x

# 项目名称 foo, bar
project=foo
# 每天凌晨3点备份MySQL数据库
today=$(/bin/date '+%Y%m%d')
log_file=/data/logs/xtrabackup/$project-$today.log
log_dir=$(dirname $log_file)
if [ ! -d $log_dir ]; then
    mkdir -p $log_dir
fi

# 全量备份
#/root/bin/myxtrabackup_full.sh $project >> $log_file 2>&1
# 增量备份
/root/bin/myxtrabackup_incr.sh $project >> $log_file 2>&1
