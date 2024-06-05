#!/bin/bash

# 檢查參數數量是否正確
if [ $# -ne 2 ]; then
    echo "Error: Invalid number of arguments"
    echo "Usage: $0 <filesdir> <searchstr>"
    exit 1
fi

filesdir=$1
searchstr=$2

# 檢查filesdir是否為目錄
if [ ! -d "$filesdir" ]; then
    echo "Error: $filesdir is not a directory"
    exit 1
fi

# 計算文件數量和匹配行數
num_files=$(find "$filesdir" -type f | wc -l)
num_matching_lines=$(grep -r "$searchstr" "$filesdir" | wc -l)

# 打印結果
echo "The number of files are $num_files and the number of matching lines are $num_matching_lines"
