#!/bin/bash

# ZABBIX 管理 => 报警媒介类型
# 名称 钉钉告警
# 类型 脚本
# 脚本名称 send-dingding.sh
# /usr/lib/zabbix/alertscripts/send-dingding.sh
# 脚本参数 {ALERT.SENDTO}   用户 => 报警媒介 配置收件人（手机号）
#          {ALERT.MESSAGE}
#
# 
# 选项
#   并发会话
#   尝试次数 3
#   尝试间隔 10s

# 钉钉机器人 webhook
# PC版钉钉=》个人头像=》机器人管理=》群组
# 新版本有关键词校验，所以告警内容里要包含指定的关键词
ACCESS_TOKEN='THE-ACCESS-TOKEN'
API_URL='https://oapi.dingtalk.com/robot/send'
API_URL="$API_URL?access_token=${ACCESS_TOKEN}"

CMD_CAT="/bin/cat"
CMD_CURL="/usr/bin/curl"
MOBILE_NUMBER=$1    # 手机号码
MESSAGE_UTF8=$2     # 告警内容

MESSAGE(){
${CMD_CAT} <<EOF
{
   "msgtype": "text",
   "text": {"content":"$MESSAGE_UTF8"},
   "at": {"atMobiles":["$MOBILE_NUMBER"],"isAtAll":false}
}
EOF
}

# 当前时间戳
TIME_STAMP=`date +%Y%m%d%H%M%S`

# Send it
$CMD_CURL -i \
-H "Content-Type:application/json;charset=utf-8" \
-X POST --data "$(MESSAGE)" "$API_URL"
