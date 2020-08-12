#!/bin/sh
. /etc/os-release

get_day=$(uci get k3screenctrl.@general[0].check_stable)
WAN_IFNAME=$(uci get network.wan.ifname)
MAC_ADDR=$(ifconfig $WAN_IFNAME | grep -oE "([0-9A-Z]{2}:){5}[0-9A-Z]{2}")

CPU_TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))*C"

now_version(){
  STABLE_VERSION=$(wget -qO- https://downloads.openwrt.org/|grep '<strong>' | grep -oE '\d+\.\d+\.\d+' | head -n1)
}

if [ -s /tmp/os_version ]; then
  cur_time=$(date +%s)
  last_time=$(date -r /tmp/os_version +%s)
  time_tmp=$(($cur_time-$last_time))
  if [ ${time_tmp:=0} -gt $((${get_day:-1}*86400)) ]; then
    now_version
    if [ -n "$STABLE_VERSION" ]; then
      rm -f /tmp/os_version
      echo $STABLE_VERSION > /tmp/os_version
    fi
  else
    STABLE_VERSION=$(cat /tmp/os_version)
  fi
else
  now_version
  if [ -n "$STABLE_VERSION" ]; then
    echo $STABLE_VERSION > /tmp/os_version
  fi
fi

  
echo K3 #型号
echo ${CPU_TEMP:=0} #H/W(heardware)改温度
echo ${VERSION:=0} #软件版本
echo ${STABLE_VERSION:=0} #最新openwrt版本
echo $MAC_ADDR #MAC地址