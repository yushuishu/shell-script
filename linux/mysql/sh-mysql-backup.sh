#!/bin/bash
shopt -s globstar

# 用途：备份MYSQL数据库

# ================================================== 使用此脚本，只需修改这里的变量即可 ===================================
# MYSQL 可执行文件目录
MYSQL_HOME="/opt/mysql/mysql8/bin"
# 备份文件存储目录
MYSQL_BACKUP_DIR="/opt/mysql_backup"
# 备份的数据库
MYSQL_BACKUP_DB_NAME="bash_demo"
# 删除 ... 天之前的备份文件
DEL_BACKUP_DAY="7"
# 备份数据库ip
MYSQL_HOST="127.0.0.1"
# 备份数据库端口
MYSQL_PORT="3360"
# 用户名
MYSQL_USER="root"
# 用户密码
MYSQL_PASSWORD="123456"
# ========================================================= 输入参数 =========================================================
if [ -n "$1" ]; then
    if [[ $1 = "--help" ]] || [[ $1 = "-help" ]] || [[ $1 = "-h" ]]; then
        echo "****************************** 脚本使用说明 *****************************"
        echo "用途：备份指定的数据库"
        echo "参数：参数                    是否必传    说明"
        echo "      --help; -help; -h        false      查看脚本使用说明"
        echo "      -n                       false      指定要备份的数据库，默认备份的数据库是：demo"
        echo "备注：无"
        echo "************************************************************************"
        exit 0
    else
        while getopts ":n:" opt; do
            case $opt in
            n)
                MYSQL_BACKUP_DB_NAME="$OPTARG"
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

echo -e "\033[36m/////////////////////////////////////// sh-mysql-backup.sh ////////////////////////////////////////////\033[0m"


# 获取当前日期
year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
MYSQL_BACKUP_DATE="${year}-${month}-${day}"

# 查找当前日期，有多少个备份文件
file_count=$(find "${MYSQL_BACKUP_DIR}" -name "${MYSQL_BACKUP_DB_NAME}_${MYSQL_BACKUP_DATE}_*.sql" | wc -l)
file_count=$((file_count + 1))

# 当前要备份的文件路径和文件名
mysql_backup_file="${MYSQL_BACKUP_DIR}/${MYSQL_BACKUP_DB_NAME}_${MYSQL_BACKUP_DATE}_${file_count}.sql"

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
long_ago_backup_file_list=("${MYSQL_BACKUP_DIR}/${MYSQL_BACKUP_DB_NAME}_${long_ago_backup_date}"_*.sql)
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
echo "开始备份数据库: ${MYSQL_BACKUP_DB_NAME}"
for ((i = 1; i <= total_points; i++)); do
    echo -n "."
    sleep $interval
done
echo "备份保存路径: ${mysql_backup_file}"
sleep 5s

# 执行数据库备份命令，当前时刻的数据，即今天的数据
$MYSQL_HOME/mysqldump -h$MYSQL_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -B $MYSQL_BACKUP_DB_NAME > $mysql_backup_file


