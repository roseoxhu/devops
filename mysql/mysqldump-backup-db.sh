#!/bin/sh

###########################################################
# MySQL数据库备份 配合定时任务在凌晨闲时执行（会锁表）
# based on MySQL server 5.7.26
###########################################################

# 备份日期与路径
BACKUP_DATE=`date +%Y%m%d`
BACKUP_HOME=/data/backup/mysql
MYSQL_USER=root
MYSQL_PASS='password-for-root'
BACKUP_CMD="/usr/local/mysql/bin/mysqldump --force --default-character-set=utf8mb4 --comments --routines --triggers --quick -u$MYSQL_USER -p$MYSQL_PASS"

# 定义需要备份的数据库
# DATABASES=('confluence' 'crowd' 'jira' 'zentao' 'zentaopro')
DATABASES=('foo' 'bar' 'baz')

echo "[$(date '+%F %T')] Start backup"
# 创建备份目录
BACKUP_TO=$BACKUP_HOME/$BACKUP_DATE
mkdir -p "$BACKUP_TO"

if [ -d $BACKUP_TO ]; then
    echo "[$(date '+%F %T')] Backup to: $BACKUP_HOME/$BACKUP_DATE";
    
    for dbname in ${DATABASES[@]}; do
        echo -n "[$(date '+%F %T')]    Backup $dbname"
        # $BACKUP_CMD $dbname | gzip > $BACKUP_TO/$dbname.sql.gz
		# yum -y install pigz
        $BACKUP_CMD $dbname | pigz > $BACKUP_TO/$dbname.sql.gz
    done
else
    echo "[$(date '+%F %T')] ERROR: Can't mkdir $BACKUP_TO"
fi

unset DATABASES # 删除整个数组
echo "[$(date '+%F %T')] Done backup"
