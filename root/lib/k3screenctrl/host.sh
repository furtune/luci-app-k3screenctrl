#!/bin/bash
# Copyright (C) 2020 yiguihai https://github.com/yiguihai

device_list=(
Unknow
bad78c/0ad0b6/
a4492c/13ec70/
02e59b/45d65d/77389b/
3bc578/
cdc7ab/
17c828/adfd89/94c046/
fce272/1f2c96/
Honor
d00dda/5ef918/
113286/
5e2668/d168e4/
e2d4a9/
be8fe0/cb2746/11cb45/0ecd4d/05481c/d9ee80/015487/c22613/
e59a88/6aa06f/
723509/9d3957/fcab40/4d6ef1/9523cc/cc3f67/655c08/acf395/94f004/54a748/a0c6e3/b5e8f3
f2462c/
67a6a5/3ec88f/
fc9359/
c2b294/aec73f/196d6c/79dcfc/1a6f0d/
79fc30/cc38e1/6addb9/bf18df/df71bc/e28edf/d23e89/d49e38/56284f/27fef0/f4f6da/7f0022/
ecadfc/
ba655a/505a97/e01f0d/f529a5/
7c0dcb/a40ae3/674aa9/b2df7f/
ThinkPad
TongfangPC
217f81/8df7cb/67dbfb/
bd8015/06d1f0/b1d462/
8601c5/e2f82f/9ce644/
0a4a6c/
)

online_list=($(grep -v "0x0" /proc/net/arp | grep "br-lan" |awk '{print $1}'))
offline_list=($(grep "0x0" /proc/net/arp | grep "br-lan" |awk '{print $1}'))
mac_online_list=($(grep -v "0x0" /proc/net/arp | grep "br-lan" |awk '{print $4}'))
if [ ! -f /tmp/device_icon.log ]; then
  touch /tmp/device_icon.log
fi
if [ ! -d /tmp/speed ]; then
  mkdir /tmp/speed
fi


#上传
iptables -C INPUT -j SPEED_UP 2>/dev/null
if [ $? -ne 0 ]; then
  iptables -N SPEED_UP
  iptables -I INPUT -j SPEED_UP
fi

#下载
iptables -C OUTPUT -j SPEED_DOWN 2>/dev/null
if [ $? -ne 0 ]; then
  iptables -N SPEED_DOWN
  iptables -I OUTPUT -j SPEED_DOWN
fi

ret_data(){
  #grep -E "^([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})$"
  unset -v logo dev_cut mac_exist remarks ol_name
  while IFS= read -r line; do    
    if [ "${1:-none}" = "${line##*|}" ]; then
      logo=${line%%|*}
      remarks=$(echo $line|cut -d\| -f2)
      continue
    fi
  done < /tmp/device_icon.log
  if [ -s /etc/config/k3screenctrl ]; then
    local dev_cut=$(grep 'config device_custom' /etc/config/k3screenctrl|wc -l)
  fi
  if [ -z "$logo" -a ${dev_cut:-0} -ge 1 ]; then
    local mac_exist=$(grep -i "$1" /etc/config/k3screenctrl) #忽略大小写匹配
    if [ -n "$mac_exist" ]; then
      for ((i=0;i<${dev_cut:-0};i++)); do
        local mac_exist=$(uci get k3screenctrl.@device_custom[$i].mac 2>/dev/null)
        #转换大小写 https://blog.csdn.net/weixin_30897233/article/details/95963472
        if [ "${1:-none}" = "${mac_exist,,}" ]; then
          logo=$(uci get k3screenctrl.@device_custom[$i].icon 2>/dev/null)
          remarks=$(uci get k3screenctrl.@device_custom[$i].name 2>/dev/null)
          echo "$logo|$remarks|$1" >> /tmp/device_icon.log
        fi
      done
    fi
  fi
  if [ -z "$logo" ]; then
    local ol_name=$(wget -qO- --no-check-certificate -U 'curl/7.65.0' http://www.atoolbox.net/api/GetMacManufacturer.php?mac=$1|cut -d\" -f2)
    if [ -n "$ol_name" -a "$ol_name" != "null" ]; then
      local ol_name=$(echo "$ol_name"|md5sum)
      local ol_name=${ol_name:0:6}
    fi
    for ((i=0;i<${#device_list[@]};i++)); do
      IFS='/'
      for j in ${device_list[i]}; do
        if [ "${j:-none}" = "$ol_name" ]; then
          logo=$i
          echo "$logo||$1" >> /tmp/device_icon.log
          break 2
        fi
      done
    done
  fi
  echo ${logo:-0}/$remarks
}
echo ${#mac_online_list[@]} #接入设备在线总数量
for ((i=0;i<${#mac_online_list[@]};i++)); do
  ret_dat=$(ret_data ${mac_online_list[i]})
  logo[i]=${ret_dat%/*}
  hostname[i]=${ret_dat#*/}
  if [ -s /tmp/dhcp.leases -a -z "${hostname[i]}" ]; then
    hostname[i]=$(grep ${mac_online_list[i]} -w /tmp/dhcp.leases | awk '{print $4}' | awk -F '-' '{print $1}')
  fi
  if [ -z "${hostname[i]}" -o "${hostname[i]}" = "*" ]; then
    hostname[i]=${online_list[i]##*.}
  fi
  
  if [ ! -s /tmp/speed/${online_list[i]} ]; then
    echo 0 > /tmp/speed/${online_list[i]}
    echo 0 >> /tmp/speed/${online_list[i]}
  fi
  iptables -nw -L SPEED_UP|grep -w "${online_list[i]}" >/dev/null
  if [ $? -ne 0 ]; then
    iptables -w -A SPEED_UP -s ${online_list[i]} #上传
  fi
  iptables -nw -L SPEED_DOWN|grep -w "${online_list[i]}" >/dev/null
  if [ $? -ne 0 ]; then
    iptables -w -A SPEED_DOWN -d ${online_list[i]} #下载
  fi
  
  last_speed_up=$(cut -d$'\n' -f,1 /tmp/speed/${online_list[i]})
  last_speed_dw=$(cut -d$'\n' -f,2 /tmp/speed/${online_list[i]})
  now_speed_up=$(iptables -w -vxn -L SPEED_UP --line-number|grep -w "${online_list[i]}" | awk '{print $3}')
  now_speed_dw=$(iptables -w -vxn -L SPEED_DOWN --line-number|grep -w "${online_list[i]}" | awk '{print $3}')
  up_sp[i]=$(($now_speed_up - $last_speed_up))
  dw_sp[i]=$(($now_speed_dw - $last_speed_dw))

  echo "${hostname[i]}" #接入设备名
  echo "${dw_sp[i]:-0}" #下载速度 KB/s 
  echo "${up_sp[i]:-0}" #上传速度 KB/s
  echo ${now_speed_up:-0} > /tmp/speed/${online_list[i]}
  echo ${now_speed_dw:-0} >> /tmp/speed/${online_list[i]}
  echo "${logo[i]}" #所属图标
done
for ((j=0;i<${#offline_list[@]};j++)); do
  if [ -s /tmp/speed/${offline_list[j]} ]; then
    rm -rf /tmp/speed/${offline_list[j]}
  fi
  iptables -C SPEED_UP -s ${online_list[j]} 2>/dev/null
  if [ $? -eq 0 ]; then
    iptables -D SPEED_UP -s ${online_list[j]} #上传
  fi
  iptables -C SPEED_DOWN -d ${online_list[j]} 2>/dev/null
  if [ $? -eq 0 ]; then
    iptables -D SPEED_DOWN -d ${online_list[j]} #下载
  fi
done