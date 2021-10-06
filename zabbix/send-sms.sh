#!/bin/bash

# ZABBIX 管理 => 报警媒介类型
# 名称 SMS告警
# 类型 脚本
# 脚本名称 send-sms.sh
# /usr/lib/zabbix/alertscripts/send-sms.sh
# 脚本参数 {ALERT.SENDTO}   用户 => 报警媒介 配置收件人（手机号）
#          {ALERT.SUBJECT}
#          {ALERT.MESSAGE}
#
# 
# 选项
#   并发会话
#   尝试次数 3
#   尝试间隔 10s

# chown -R zabbix.zabbix /usr/lib/zabbix/logs/sms.log
LOG_FILE=/usr/lib/zabbix/logs/sms.log
if [ ! -f "$LOG_FILE" ]; then
    touch $LOG_FILE
fi
# echo -e "\n$1 '$2'" >> $LOG_FILE

# 短信接入网关
# 大汉三通短信网关 账号、授权token等参数
ACCOUNTSID='THE-ACCOUNTSID'
AUTHTOKEN='THE-AUTHTOKEN'
APIURL='https://sms.dahancloud.com/API/sendMessage'
APPID='THE-APPID'
# 大汉三通短信网关 短信模板(不同服务商需做调整，不一定是模板ID)
# 1234  服务监控告警    会员通知        XX管家        服务异常{1}
TEMPLATEID=1234

CMD_CAT="/bin/cat"
CMD_CURL="/usr/bin/curl"
# $1={ALERT.SENDTO}
MOBILE_NUMBER="$1"    # 手机号码
# $2={ALERT.SUBJECT}
MESSAGE_UTF8="$2"     # 短信内容, 逗号分隔的多个值
# $3={ALERT.MESSAGE}

MESSAGE(){
${CMD_CAT} <<EOF
{
   "appId": "$APPID",
   "templateId": "$TEMPLATEID",
   "datas": ["$MESSAGE_UTF8"],
   "to": "$MOBILE_NUMBER"
}
EOF
}

# 当前时间戳
TIME_STAMP=`date +%Y%m%d%H%M%S`
# tr [:lower:] [:upper:], echo lowercase to uppercase | tr [a-z] [A-Z]
SIGN=`echo -n "${ACCOUNTSID}${AUTHTOKEN}${TIME_STAMP}" | md5sum | cut -d ' ' -f1 | tr [:lower:] [:upper:]`
SMS_URL="$APIURL?sig=${SIGN^^}"
AUTH=`echo -n "${ACCOUNTSID}:${TIME_STAMP}" | base64`

# Send it
echo -e "\n$TIME_STAMP '$1' '$2' '$3'" >> $LOG_FILE

${CMD_CURL} -i \
-H "Accept:application/json" \
-H "Content-Type:application/json;charset=utf-8" \
-H "Authorization:$AUTH" \
-X POST --data "$(MESSAGE)" "$SMS_URL"
