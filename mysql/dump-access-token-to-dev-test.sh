#!/bin/sh

###########################################################
# 1. 需授权'phper'@'DBMASTER_IP': 
# GRANT ALL PRIVILEGES ON `foobar`.* TO 'phper'@'xxx.xxx.xxx.%' identified by 'change-it'
# 2. 防火墙对 DBMASTER_IP 开启3306端口
# 3. crontab
# 导出微信access token到开发&测试环境
# */5 * * * * /root/bin/dump-access-token-to-dev-test.sh
###########################################################


MYSQL_USER=phper
# 包含特殊字符需要引号括起来
MYSQL_PASS='change-it'
MYSQLDUMP_CMD=/usr/local/mysql/bin/mysqldump
MYSQLDUMP_OPTS="-n -t --quick --replace --skip-opt"
MYSQL_CMD=/usr/local/mysql/bin/mysql
DATABASE=foobar
TABLE=access_token

# 通过管道导出导入
# Test Env
HOST_TEST=xxx.xxx.xxx.xxx
$MYSQLDUMP_CMD -u$MYSQL_USER -p$MYSQL_PASS $MYSQLDUMP_OPTS $DATABASE $TABLE | $MYSQL_CMD -h$HOST_TEST -u$MYSQL_USER -p$MYSQL_PASS $DATABASE

# Dev Env
HOST_DEV=xxx.xxx.xxx.xxx
$MYSQLDUMP_CMD -u$MYSQL_USER -p$MYSQL_PASS $MYSQLDUMP_OPTS $DATABASE $TABLE | $MYSQL_CMD -h$HOST_DEV -u$MYSQL_USER -p$MYSQL_PASS $DATABASE
