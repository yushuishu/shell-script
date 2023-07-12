#!/bin/bash

if [ -n "$1" ] ;then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]];then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：备份指定的数据库"
        echo "参数：无"
        echo "备注：如果要在定时任务中，使用执行脚本，需要修改脚本内容，指定PG数据库密码，修改变量：PG_PASSWORD，并修改末尾的执行命令"
        echo "************************************************************************"
        exit 0
    else
        echo "参数无效：请使用 --help、-help、-h 查看脚本使用说明"
    fi
fi


echo -e "\033[36m/////////////////////////////////////// sh-pg-backup.sh ////////////////////////////////////////////\033[0m"


# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
# postgresql 安装目录
PG_HOME="/opt/postgresql14/bin"
# postgresql 数据目录
PG_DATA="/opt/postgresql14/data"
# 备份文件存储目录
PG_BACKUP_DIR="/opt/pg_backup"
# 备份的数据库
PG_BACKUP_DB_NAME="cs31_test"
# 删除 ... 天之前的备份文件
DEL_BACKUP_DAY="7"
# 备份数据库ip
PG_HOST="127.0.0.1"
# 备份数据库端口
PG_PORT="5432"
# 用户名
PG_USER="postgres"
# 用户密码
PG_PASSWORD="123456"
# ====================================================================================================================

# root用户不能使用psql或者pg_dump等pg命令，因此创建一个软连接
ln -s ${PG_HOME}/pg_dump /usr/sbin/pg_dump

# 获取当前日期
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
PG_BACKUP_DATE="${year}-${month}-${day}"

# 查找当前日期，有多少个备份文件
file_count=$(find "${PG_BACKUP_DIR}/${PG_BACKUP_DB_NAME}_${PG_BACKUP_DATE}_*.backup" | wc -l)
file_count=$((file_count + 1))

# 当前要备份的文件路径和文件名
pg_backup_file="${PG_BACKUP_DIR}/${PG_BACKUP_DB_NAME}_${PG_BACKUP_DATE}_${file_count}.backup"

# 计算 DEL_BACKUP_DAY 天前的日期
long_ago_backup_date=$(date -d "${DEL_BACKUP_DAY} days ago" +%Y-%m-%d)

# DEL_BACKUP_DAY 天前备份的文件路径和文件名
long_ago_backup_file="${PG_BACKUP_DIR}/${PG_BACKUP_DB_NAME}_${long_ago_backup_date}_*.backup"

# 检查 DEL_BACKUP_DAY 天前的备份文件是否已存在，如存在则删除
if [ -e "${long_ago_backup_file}" ]; then
    rm -f "${long_ago_backup_file}"
fi

# 执行数据库备份命令，当前时刻的数据，即今天的数据
"${PG_HOME}/pg_dump" -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" -W -Fc -b -v -f "${pg_backup_file}" "${PG_BACKUP_DB_NAME}"
# 定时任务场景中，使用的命令
"${PG_HOME}/pg_dump" -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" -W -Fc -b -v -f "${pg_backup_file}" "${PG_BACKUP_DB_NAME}"
