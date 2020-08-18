#!/bin/sh

# Basic vars
TEMP_FILE="/tmp/wan_speed"
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

WAN_IFNAME=`ip route get 8.8.8.8 | awk -- '{printf $5}'`
if [ -z "$WAN_IFNAME" ]; then
  WAN_IFNAME=`echo $WAN_STAT | jsonfilter -e "@.l3_device"` # pppoe-wan
  if [ -z "$WAN_IFNAME" ]; then
    WAN_IFNAME=`echo $WAN_STAT | jsonfilter -e "@.device"` # eth0.2
    if [ -z "$WAN_IFNAME" ]; then
      WAN_IFNAME=`uci get network.wan.ifname` # eth0.2
    fi
  fi
fi

CURR_STAT=`cat /proc/net/dev | grep $WAN_IFNAME | sed -e 's/^ *//' -e 's/  */ /g'`
CURR_DOWNLOAD_BYTES=`echo $CURR_STAT | cut -d' ' -f2`
CURR_UPLOAD_BYTES=`echo $CURR_STAT | cut -d' ' -f10`

if [ -e "$TEMP_FILE" ]; then
  LAST_UPLOAD_BYTES=`cut -d$'\n' -f,1 $TEMP_FILE`
  LAST_DOWNLOAD_BYTES=`cut -d$'\n' -f,2 $TEMP_FILE`
fi

echo ${CURR_UPLOAD_BYTES:-0} > $TEMP_FILE
echo ${CURR_DOWNLOAD_BYTES:-0} >> $TEMP_FILE

UPLOAD_BPS=$((${CURR_UPLOAD_BYTES:-0}-${LAST_UPLOAD_BYTES:-0}))
DOWNLOAD_BPS=$((${CURR_DOWNLOAD_BYTES:-0}-${LAST_DOWNLOAD_BYTES:-0}))

if [ $UPLOAD_BPS -lt 0 ]; then
  UPLOAD_BPS=0
fi
if [ $DOWNLOAD_BPS -lt 0 ]; then
  DOWNLOAD_BPS=0
fi

echo $CONNECTED
echo $UPLOAD_BPS
echo $DOWNLOAD_BPS
