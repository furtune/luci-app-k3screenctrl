#!/bin/sh

key=$(uci get k3screenctrl.@general[0].weather_key)
city=$(uci get k3screenctrl.@general[0].weather_city)
week=$(date "+%u")
intervals=$(uci get k3screenctrl.@general[0].weather_delay)
json_file=/tmp/weather.json

now_weather(){
  #wanip=$(wget -qO- -U 'curl/7.65.0' https://myip.ipip.net/|grep -oE '([0-9]+\.){3}[0-9]+?')
  unset -v weather_json
  if [ -n "$key" -a -n "$city" ]; then
    weather_json=$(wget -qO- --no-check-certificate -U 'curl/7.65.0' "http://api.seniverse.com/v3/weather/now.json?key=${key}&location=${city}&language=zh-Hans&unit=c" 2>/dev/null)
  fi
}


#unset -v city weather_json
if [ -s $json_file ]; then
  cur_time=$(date +%s)
  last_time=$(date -r $json_file +%s)
  time_tmp=$(($cur_time-$last_time))
  if [ $time_tmp -gt $((${intervals:-60}*60)) ]; then
    now_weather
    if [ -n "$weather_json" ]; then
      rm -f $json_file
      echo $weather_json > $json_file
    fi
  else
    weather_json=$(cat $json_file 2>/dev/null)
    city=$(jsonfilter -s $weather_json -e '@.results[0].location.name')
  fi
else
  now_weather
  if [ -n "$weather_json" ]; then
    echo $weather_json > $json_file
  fi
fi


if [ -n "$(jsonfilter -s $weather_json -e '@.results[0].last_update')" ]; then
  temperature=$(jsonfilter -s $weather_json -e '@.results[0].now.temperature');
  code=$(jsonfilter -s $weather_json -e '@.results[0].now.code');
fi

echo ${city:-北京} #城市
echo ${temperature:-0} #温度
echo $(date "+%Y-%m-%d") #日期
echo $(date "+%H:%M") #时间
echo ${code:-0} #天气
echo ${week//7/0} #星期
if [ -n "$temperature" -a -n "$code" ]; then
  echo 0
else
  echo 1
fi
