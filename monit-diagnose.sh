#!/usr/bin/env bash
# name linux monit-state.sh
# Author: jackliu (Jianqiu Liu)
# Site: https://github.com/ljq
# Blog: defense.ink
# Email: stackgo@163.com
# Date: 2022-01-29
# Version: 1.0.0

# script version
CLI_VERSION="1.0.0"

# Terminal color 
GREEN_COLOR="\033[32m"
CYAN_COLOR="\033[36m"
YELLOW_COLOR="\033[43;37m"
RED_COLOR="\033[31m"
GREEN_BG_COLOR="\033[47;42m"
CYAN_BG_COLOR="\033[47;46m"
RES="\033[0m"

# Help　info
HELP_INFO=$(
    cat <<EOF
[helptext]
    -h|help : Show help info.
    -g|-gui|gui : Default GUI(if OS is supported.) mode.
EOF
)

#---------------- cli  module -------------------

# nginx log path
nginx_log_file="/var/log/nginx/access.log"

select_cmd_list=("os" "nginx")

sub_os_list=(
    "对连接的IP按连接数量进行排序"

    "查看TCP连接状态"

    "查看80端口连接数最多的【N】个IP"

    "查找较多time_wait连接"

    "查找较多的SYN连接"

    "查看当前并发访问数"

    "查看所有连接请求"

    "查看访问某一ip的所有外部连接IP(数量从多到少)"

    "根据端口查找进程"

    "查看443端口连接数最多的【N】个IP"
)

sub_nginx_list=(
    "查看访问记录，从1000行开始到3000"

    "查看访问记录，从1000行开始，显示200行"

    "根据访问IP统计UV"

    "统计访问URL统计PV"

    "查询访问最频繁的URL"

    "查询访问最频繁的IP"

    "通过日志查看含有send的url,统计ip地址的总连接数"

    "通过日志查看当天指定ip访问次数过的url和访问次数"
)

function mainmenu() {
    PS3='请选择服务: '
    options=($@)
    select opt in "${options[@]}"; do
        submenu_${opt} ${sub_os_list[@]}
        break
    done
}

function submenu_os() {
    PS3='请选择要执行的OS任务: '
    options=($@)
    select opt in "${options[@]}"; do
        num=${REPLY}
        if [ $num -gt ${#options[@]} -o $num -lt 0 ]; then
            echo -e "${YELLOW_COLOR}[Warning]非法输入${RES}"
            exit 0
        else
            echo -e "${CYAN_COLOR}${opt}${RES}\n"
            cmd_os ${num}
            break
        fi
    done
}

function submenu_nginx() {
    PS3='请选择要执行的Nginx任务: '
    options=($@)
    select opt in "${options[@]}"; do
        num=${REPLY}
        if [ $num -gt ${#options[@]} -o $num -lt 0 ]; then
            echo -e "${YELLOW_COLOR}[Warning]非法输入${RES}"
            exit 0
        else
            echo -e "${CYAN_COLOR}${opt}${RES}\n"
            cmd_nginx ${num}
            break
        fi
    done
}

#---------------- cli cmds -------------------

function cmd_os() {
    num=$1
    case ${num} in
    1)
        # 对连接的IP按连接数量进行排序：
        netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n
        ;;
    2)
        # 查看TCP连接状态：
        netstat -nat | awk '{print $6}' | sort | uniq -c | sort -rn
        ;;
    3)
        #查看80端口连接数最多的【N】个IP
        echo "请输入80端口查询的IP数量："
        read IP_NUM
        if [ -z $IP_NUM ]; then
            echo -e "${YELLOW_COLOR}[Warning]IP数量输入有误${RES}"
        fi
        netstat -anlp tcp | grep 80 | grep tcp | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -n ${IP_NUM}
        ;;
    4)
        #查找较多time_wait连接
        netstat -n | grep TIME_WAIT | awk '{print $5}' | sort | uniq -c | sort -rn | head -n 20
        ;;
    5)
        #查找较多的SYN连接：
        netstat -an | grep SYN | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -nr | more
        ;;
    6)
        #查看当前并发访问数：
        netstat -an | grep ESTABLISHED | wc -l
        ;;
    7)
        #查看所有连接请求
        netstat -tn 2>/dev/null
        ;;
    8)
        #查看访问某一ip的所有外部连接IP(数量从多到少)
        echo "请输入查询的IP地址："
        read IP
        if [ -z $IP ]; then
            echo -e "${YELLOW_COLOR}[Warning]输入有误${RES}"
        fi
        netstat -nt | grep ${IP} | awk '{print $5}' | awk -F: '{print ($1>$4?$1:$4)}' | sort | uniq -c | sort -nr | head
        ;;
    9)
        #根据端口查找进程：
        echo "请输入查询的端口号(Port)："
        read PORT
        if [ -z $PROT ]; then
            echo -e "${YELLOW_COLOR}[Warning]端口号输入有误${RES}"
        fi
        netstat -ntlp tcp | grep ${PORT} | awk '{print $7}' | cut -d/ -f1
        ;;
    10)
        #查看443端口连接数最多的【N】个IP
        echo "请输入443端口查询的IP数量："
        read IP_NUM
        if [ -z $IP_NUM ]; then
            echo -e "${YELLOW_COLOR}[Warning]IP数量输入有误${RES}"
        fi
        netstat -anlp tcp | grep 443 | grep tcp | awk '{print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -nr | head -n ${IP_NUM}
        ;;
    esac
}

function cmd_nginx() {
    num=$1
    if [ ! -f ${nginx_log_file} -o ! -s ${nginx_log_file} ]; then
        echo "日志文件不存在或日志内容为空"
        exit
    fi
    case $num in
    1)
        #查看访问记录，从1000行开始到3000：
        cat ${nginx_log_file} | head -n 3000 | tail -n 1000
        ;;
    2)
        #查看访问记录，从1000行开始，显示200行：
        cat ${nginx_log_file} | tail -n +1000 | head -n 200
        ;;
    3)
        #根据访问IP统计UV：
        awk '{print $1}' ${nginx_log_file} | sort | uniq -c | wc -l
        ;;
    4)
        #统计访问URL统计PV：
        awk '{print $7}' ${nginx_log_file} | wc -l
        ;;
    5)
        #查询访问最频繁的URL：
        awk '{print $7}' ${nginx_log_file} | sort | uniq -c | sort -n -k 1 -r | more
        ;;
    6)
        #查询访问最频繁的IP：
        awk '{print $1}' ${nginx_log_file} | sort | uniq -c | sort -n -k 1 -r | more
        ;;
    7)
        #通过日志查看含有send的url,统计ip地址的总连接数：
        cat ${nginx_log_file} | grep "send" | awk '{print $1}' | sort | uniq -c | sort -nr
        ;;
    8)
        #通过日志查看当天指定ip访问次数过的url和访问次数：
        echo "请输入当天查询的目标IP地址："
        read IP
        if [ -z $IP ]; then
            echo -e "${YELLOW_COLOR}[Warning]输入有误${RES}"
        fi
        cat ${nginx_log_file} | grep ${IP} | awk '{print $7}' | sort | uniq -c | sort -nr
        ;;
    esac

}

# help
case $1 in
"-v" | "-V" | "--version")
    echo -e "cli script version：${CLI_VERSION}."
    exit
    ;;
"-h" | "-help" | "--help")
    echo -e "${HELP_INFO}"
    exit
    ;;
"-g" | "-gui" | "gui")
    echo -e "Coming soon."
    exit
    ;;
esac

# ---------------------- Task Process -------------------------

# command check
cmds=("netstat" "awk" "cat" "whiptail" "nginx")
for cmd in "${cmds[@]}"; do
  type ${cmd} >/dev/null 2>&1 || {
      echo >&2 "[Warning] ${cmd} is not found. Please install it and try again.\n"
      exit 1
  }
done

mainmenu ${select_cmd_list[@]}

# ---------------------- task exec -------------------------
