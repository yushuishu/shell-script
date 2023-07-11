#!/bin/bash

echo -e "\033[36m/////////////////////////////////////// sh-pg-backup.sh ////////////////////////////////////////////\033[0m"

# 定义备份目录和文件名
BACKUP_DIR="/path/to/backup/directory"
BACKUP_FILE="pg_backup_$(date +%Y%m%d%H%M%S).sql"

# 进入到备份目录
cd $BACKUP_DIR

# 使用 pg_dump 备份数据库
pg_dump -U postgres <数据库名称> > $BACKUP_FILE

