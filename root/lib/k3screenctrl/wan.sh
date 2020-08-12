#!/bin/sh

# Basic vars
WAN_STAT=`ifstatus wan`
WAN6_STAT=`ifstatus wan6`

# Internet connectivity
IPV4_ADDR=`echo $WAN_STAT | jsonfilter -e "@['ipv4-address']"`
IPV6_ADDR=`echo $WAN6_STAT | jsonfilter -e "@['ipv6-address']"`

if [ -n "$IPV4_ADDR" -o -n "$IPV6_ADDR" ]; then
    CONNECTED=1
else
    CONNECTED=0
fi

echo $CONNECTED
# 目前网速状态无法正常显示索性删除
echo 0
echo 0