#!/bin/sh

############################################################
# 找出MySQL锁表连接线程，并杀掉
############################################################
now=`date '+%F %T'`
suffix=`date '+%Y%m%d%H%M%S'`
lock_keyword="lock"
show_processlist='show full processlist'
mysql_cmd="/usr/bin/mysql --default-character-set=utf8 -uroot -p******"

# 导出全部连接线程
processlist_full_file=/tmp/processlist_full_${suffix}.txt
echo "[$(date '+%F %T')] Show full processlist to $processlist_full_file"
echo "$mysql_cmd -e '$show_processlist' > $processlist_full_file"
$mysql_cmd -e "$show_processlist" > $processlist_full_file
echo

# 导出包含 Query 连接线程
processlist_query_file=/tmp/processlist_query_${suffix}.txt
echo "[$(date '+%F %T')] Show query processlist to $processlist_query_file"
echo "$mysql_cmd -e '$show_processlist' | grep -i 'Query' > $processlist_query_file"
$mysql_cmd -e "$show_processlist" | grep -i "Query" > $processlist_query_file
echo

# 导出包含 lock 连接线程
processlist_lock_file=/tmp/processlist_lock_${suffix}.txt
echo "[$(date '+%F %T')] Show $lock_keyword processlist to $processlist_lock_file"
echo "$mysql_cmd -e '$show_processlist' | grep -i 'Query' | grep -i '$lock_keyword' > $processlist_lock_file"
$mysql_cmd -e "$show_processlist" | grep -i "Query" | grep -i "$lock_keyword" > $processlist_lock_file
echo

# 拼接 kill 语句
processlist_kill_file=/tmp/processlist_kill_${suffix}.sql
echo "[$(date '+%F %T')] Show $lock_keyword processlist for kill to $processlist_kill_file"
echo "$mysql_cmd -e '$show_processlist' | grep -i 'Query' | grep -i '$lock_keyword' | awk '{print \"kill \"\$1\";\"}' > $processlist_kill_file"
$mysql_cmd -e "$show_processlist" | grep -i "Query" | grep -i "$lock_keyword" | awk '{print "kill "$1";"}' > $processlist_kill_file
echo

echo "cat $processlist_kill_file"
cat $processlist_kill_file

# 杀掉锁表连接
if [[ -s $processlist_kill_file ]]; then # 文件存在且不为空
    echo "$mysql_cmd < $processlist_kill_file"
    # $mysql_cmd < $processlist_kill_file
fi

# TODO 清理临时文件

echo "[$(date '+%F %T')] Done"
