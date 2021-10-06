#!/bin/bash
#set -xe

##############################################
# 同步SVN hotcopy备份到远程机房
# $1 必传，需要同步的文件，不支持通配符*
# $2 可选，备份日期yyyyMMdd
##############################################

# 需要建立SSH免密码登录
# 目标主机用户copier:~/.ssh/authorized_keys添加源用户id_rsa.pub
target_user=copier
target_host='REMOTE_IP'
log_prefix=/data/logs/svn-hotcopy
# 定义备份路径前缀
target_dir_prefix=/data/svn-hotcopy

src_file=$1
if [[ "${src_file}" == "" ]]; then
    echo "Usage: $0 <src_file>"
    exit 0
fi

# 指定备份日期
today=$2
if [[ "$today" == "" ]]; then
    # 不指定备份日期，默认使用当前日期
    today=$(date '+%Y%m%d')
fi
target_dir="$target_dir_prefix/$today"

log_file=$log_prefix/rsync-${today}.log
log_dir=$(dirname $log_file)
if [ ! -d $log_dir ]; then
    mkdir -p $log_dir
fi
# 清理日志文件
find ${log_dir} -maxdepth 1 -mtime +10 -exec rm -fr {} \;

# create remote dir
echo "[$(date '+%F %T')] Create target dir @$target_host:$target_dir" >> $log_file
ssh $target_user@$target_host "mkdir -p $target_dir"

# shell中使用符号"$?"来表示上一条命令执行的返回值，如果为0则代表执行成功，其他表示失败
# [ -f /etc/hosts ] && echo "Found" || echo "Not found"
# if [ $? -eq 0 ]; then
if ssh $target_user@$target_host "test -d $target_dir"; then
    echo "[$(date '+%F %T')] @$target_host:$target_dir created successful." >> $log_file
else
    echo "[$(date '+%F %T')] @$target_host:$target_dir creation failed!" >> $log_file
    exit 0
fi

# 开始同步文件
echo "[$(date '+%F %T')] rsync start" >> $log_file
echo "[$(date '+%F %T')] time rsync -alv --progress $src_file $target_user@$target_host:$target_dir/ >> $log_file 2>&1" >> $log_file
time rsync -alv --progress $src_file $target_user@$target_host:$target_dir/ >> $log_file 2>&1
echo "[$(date '+%F %T')] rsync done." >> $log_file
