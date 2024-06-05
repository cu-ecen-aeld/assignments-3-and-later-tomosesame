#!/bin/bash

# 檢查參數數量是否正確
if [ $# -ne 2 ]; then
    echo "Error: Invalid number of arguments"
    echo "Usage: $0 <writefile> <writestr>"
    exit 1
fi

writefile=$1
writestr=$2

# 創建目錄和文件，並寫入內容
mkdir -p "$(dirname "$writefile")"
echo "$writestr" > "$writefile"

# 檢查文件是否成功創建
if [ $? -ne 0 ]; then
    echo "Error: Could not create file $writefile"
    exit 1
fi
