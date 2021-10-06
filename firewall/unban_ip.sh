#!/bin/bash

###########################################################
# Unban the remote IP attack
# iptables -D INPUT -s 45.121.106.58 -j DROP
###########################################################

remote_ip=$1
if [[ "$remote_ip" == "" ]]; then
    echo "[`date '+%F %T'`] Usage: $0 <remote_ip>"
    exit 0
fi

iptables -D INPUT -s $remote_ip -j DROP
# iptables -nL INPUT --line-numbers | grep "$remote_ip"
iptables -nL INPUT --line-numbers
