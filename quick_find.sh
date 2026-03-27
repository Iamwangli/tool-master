#!/bin/bash
# quick_find.sh - 快速工具查找（简化版）

TOOL_MAP="tool_keyword_map.md"
KEYWORD="$1"

if [[ -z "$KEYWORD" ]]; then
    echo "用法: $0 <关键词>"
    echo "示例: $0 目录"
    echo "示例: $0 统计"
    exit 1
fi

echo "搜索关键词: $KEYWORD"
echo "=========================="

# 搜索工具
results=$(grep -i "$KEYWORD" "$TOOL_MAP" 2>/dev/null | head -10)

if [[ -z "$results" ]]; then
    echo "未找到匹配 '$KEYWORD' 的工具"
    echo ""
    echo "尝试以下关键词:"
    echo "  目录, 文件, 统计, 搜索, 时间, 网络, 进程, 系统"
    exit 1
fi

count=$(echo "$results" | wc -l)
echo "找到 $count 个工具:"
echo ""

# 显示结果
i=1
echo "$results" | while IFS= read -r line; do
    if [[ "$line" == "## "* ]] || [[ "$line" == "### "* ]]; then
        # 这是分类标题，跳过
        continue
    fi
    
    # 解析工具行
    tool_type=$(echo "$line" | cut -d':' -f1)
    tool_info=$(echo "$line" | cut -d':' -f2-)
    tool_name=$(echo "$tool_info" | cut -d'|' -f1 | xargs)
    keywords=$(echo "$tool_info" | cut -d'|' -f2 | xargs)
    command=$(echo "$tool_info" | cut -d'|' -f3 | xargs)
    
    echo "[$i] $tool_type: $tool_name"
    echo "    关键词: $keywords"
    echo "    命令: $command"
    echo ""
    
    ((i++))
done

echo "=========================="
echo "提示: 使用 'tool_finder.sh' 获取更多功能（排序、过滤、执行等）"