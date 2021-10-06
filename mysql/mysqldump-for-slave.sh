#!/bin/bash

###########################################################
# 搭建MySQL数据库从库，主库导出数据
# based on MySQL server 5.7.26
###########################################################

echo "[$(date '+%F %T')] Start dump"

today=$(date '+%Y%m%d')
mysql_command=/usr/bin/mysqldump
mysql_password='password-for-root'
mysql_options="--default-character-set=utf8 --comments --events --routines --triggers --quick"
mysql_options="$mysql_options -uroot -p${mysql_password} --flush-logs --single-transaction --master-data=2 --all-databases"
dump_outfile="/data/backup/$today/all-databases.sql"

mkdir -p /data/backup/$today
# echo $mysql_options
echo $dump_outfile

# time $mysql_command $mysql_options | lz4 -B4 > $dump_outfile.lz4
# yum -y install pigz
echo "$mysql_command $mysql_options | pigz > $dump_outfile.gz"
time $mysql_command $mysql_options | pigz > $dump_outfile.gz

echo "[$(date '+%F %T')] Done dump."
