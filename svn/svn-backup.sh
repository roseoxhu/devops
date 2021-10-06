#!/bin/sh

######################################################################
# SVN服务器配置定时任务，每天进行一次全量备份，备份目录以日期命名
# https://tortoisesvn.net/docs/release/TortoiseSVN_zh_CN/tsvn-repository-backup.html
# 
######################################################################

# 备份日期与路径
BACKUP_DATE=`date +%Y%m%d`
BACKUP_HOME=/data/backup/svn
# svnserve, 版本 1.6.11
BACKUP_CMD="/usr/bin/svnadmin hotcopy --clean-logs"

# 定义需要备份的代码仓库
CODE_ROOT=/data/svn/repository
# TODO 替换成实际的项目名
CODE_REPOS=('foo' 'bar')

echo "[$(date '+%F %T')] Start backup SVN repository"
for REPO_NAME in ${CODE_REPOS[@]}; do
    BACKUP_FR=${CODE_ROOT}/${REPO_NAME}
    # 创建备份目录
    BACKUP_TO=${BACKUP_HOME}/${BACKUP_DATE}/${REPO_NAME}
    mkdir -p "$BACKUP_TO"
    
    if [[ -d ${BACKUP_TO} ]]; then
        echo "[$(date '+%F %T')] Backup from $BACKUP_FR to $BACKUP_TO"
        
        # 全量热备份
        $BACKUP_CMD ${BACKUP_FR} ${BACKUP_TO} 

        # 备份完整性检查
        REVISION=$(/usr/bin/svnlook youngest ${BACKUP_TO})
        if [[ ${REVISION} -gt 0 ]]; then
            echo "[$(date '+%F %T')] Hotcopy success: $BACKUP_TO@${REVISION}"
        fi

        # 打包
        TAR_FILE=${BACKUP_HOME}/${BACKUP_DATE}/${REPO_NAME}-${BACKUP_DATE}.tar.gz
        echo "[$(date '+%F %T')] Tar and gzip to file: ${TAR_FILE}"
        tar -czf ${TAR_FILE} -C ${BACKUP_TO} .
        if [[ -e ${TAR_FILE} ]]; then
            echo "[$(date '+%F %T')] Created tar file"

            # 同步到远端服务器
            echo "[$(date '+%F %T')] Rsync tar file ..."
            /root/bin/svn-rsync.sh ${TAR_FILE}
            
            # 清理备份目录
            echo "[$(date '+%F %T')] Clean up ${BACKUP_TO} ..."
            rm -fr ${BACKUP_TO}
        fi
    fi
done

unset CODE_REPOS # 删除整个数组
echo "[$(date '+%F %T')] Done backup SVN"
