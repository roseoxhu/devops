#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# chown zabbix.zabbix send-dingding.py
# chmod +x send-dingding.py
#
# yum install python-pip
# pip install requests

import datetime
import requests
import json
import sys
import os


# https://developers.dingtalk.com/document/robots/custom-robot-access
api_url = "https://oapi.dingtalk.com/robot/send?access_token=THE-ACCESS-TOKEN"

# mkdir -p /usr/lib/zabbix/logs/
# touch /usr/lib/zabbix/logs/dingding.log
# chown zabbix.zabbix /usr/lib/zabbix/logs/dingding.log
log_file = "/usr/lib/zabbix/logs/dingding.log"

def send_msg(mobile, text):
    headers = {
        'Content-Type': 'application/json;charset=utf-8'
    }
    data = {
        "msgtype": "text",
        "text": {
            "content": text
        },
        "at": {
            "atMobiles": [
                mobile
            ],
            "isAtAll": False
        }
    }

    result = requests.post(api_url, json.dumps(data), headers=headers)
    # print(result)
    if os.path.exists(log_file):
        f = open(log_file, "a+")
    else:
        f = open(log_file, "w+")
    f.write("\n" + "--" * 40)
    
    if result.json()["errcode"] == 0:
        errmsg = "发送成功"
    else:
        errmsg = "发送失败"
    # errmsg = result.json()["errmsg"]  
    f.write("\n%s    %s    %s\n%s" % (datetime.datetime.now(), mobile, errmsg, text))
    f.close()


# ZABBIX 管理 => 报警媒介类型
# 名称 钉钉告警
# 类型 脚本
# 脚本名称 send-dingding.py
# /usr/lib/zabbix/alertscripts/send-dingding.py
# 脚本参数 {ALERT.SENDTO}   用户 => 报警媒介 配置收件人（手机号）
#          {ALERT.MESSAGE}
#
# 
# 选项
#   并发会话
#   尝试次数 3
#   尝试间隔 10s

if __name__ == '__main__':
    mobile = sys.argv[1]
    text = sys.argv[2]
    send_msg(mobile, text)
