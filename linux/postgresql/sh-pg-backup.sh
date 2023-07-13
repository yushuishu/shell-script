#!/bin/bash
shopt -s globstar

# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
# postgresql 安装目录
PG_HOME="/usr/lib/postgresql/14/bin"
# postgresql 数据目录
PG_DATA=" /var/lib/postgresql/14/main"
# 备份文件存储目录
PG_BACKUP_DIR="/opt/pg_backup"
# 备份的数据库
PG_BACKUP_DB_NAME="bash_demo"
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
# ========================================================= 输入参数 =========================================================
if [ -n "$1" ]; then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：备份指定的数据库"
        echo "参数：参数                    是否必传    说明"
        echo "      --help; -help; -h        false      查看脚本使用说明"
        echo "      -db                      false      指定要备份的数据库，默认备份的数据库是：demo"
        echo "备注：无"
        echo "************************************************************************"
        exit 0
    else
        while getopts ":db:" opt; do
            case $opt in
            h)
                echo "指定要备份的数据库: $OPTARG"
                ;;
            \?)
                echo "无效的选项: -$OPTARG，请使用 --help、-help、-h 查看脚本使用说明"
                exit 0
                ;;
            esac
        done
    fi
fi

# =============================================================================================================================

echo -e "\033[36m/////////////////////////////////////// sh-pg-backup.sh ////////////////////////////////////////////\033[0m"

# 用户权限
current_user=$USER
if [ "$current_user" != "postgres" ]; then
    # 不是postgres用户，不能使用psql或者pg_dump等pg命令，因此创建一个软连接
    ln -s ${PG_HOME}/pg_dump /usr/sbin/pg_dump
fi

# 获取当前日期
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
PG_BACKUP_DATE="${year}-${month}-${day}"

# 查找当前日期，有多少个备份文件
file_count=$(find "${PG_BACKUP_DIR}" -name "${PG_BACKUP_DB_NAME}_${PG_BACKUP_DATE}_*.backup" | wc -l)
file_count=$((file_count + 1))

# 当前要备份的文件路径和文件名
pg_backup_file="${PG_BACKUP_DIR}/${PG_BACKUP_DB_NAME}_${PG_BACKUP_DATE}_${file_count}.backup"

# 计算 DEL_BACKUP_DAY 天前的日期
long_ago_backup_date=$(date -d "${DEL_BACKUP_DAY} days ago" +%Y-%m-%d)

# 定义动画持续时间（秒）
duration=0.6
# 计算每个点的间隔时间
interval=0.1
# 计算点的总数
total_points=$(bc <<<"$duration / $interval")

for ((i = 1; i <= total_points; i++)); do
    echo -n "."
    sleep $interval
done
echo "查找${long_ago_backup_date}号所有备份文件"
# 检查 DEL_BACKUP_DAY 天前的备份文件是否已存在，如存在则删除
long_ago_backup_file_list=("${PG_BACKUP_DIR}/${PG_BACKUP_DB_NAME}_${long_ago_backup_date}"_*.backup)
list_size=0
list_size="${#long_ago_backup_file_list[@]}"
for ((i = 1; i <= total_points; i++)); do
    echo -n "."
    sleep $interval
done

if [ "$list_size" -eq 0 ] || [ "$list_size" -eq 1 ] || [ -z "${long_ago_backup_file_list[0]}" ]; then
    echo "删除${long_ago_backup_date}号所有备份文件数量：0"
else
    echo "删除${long_ago_backup_date}号所有备份文件数量：${list_size}"
    for file in "${long_ago_backup_file_list[@]}"; do
        if [ -e "$file" ]; then
            rm -f "$file"
            echo "已删除文件：$file"
        fi
    done
fi

for ((i = 1; i <= total_points; i++)); do
    echo -n "."
    sleep $interval
done
echo "开始备份数据库: ${PG_BACKUP_DB_NAME}"
for ((i = 1; i <= total_points; i++)); do
    echo -n "."
    sleep $interval
done
echo "备份保存路径: ${pg_backup_file}"
sleep 5s

# 执行数据库备份命令，当前时刻的数据，即今天的数据
PGPASSWORD="${PG_PASSWORD}" "${PG_HOME}/pg_dump" -h "${PG_HOST}" -p "${PG_PORT}" -U "${PG_USER}" -Fc -b -v -f "${pg_backup_file}" "${PG_BACKUP_DB_NAME}"
