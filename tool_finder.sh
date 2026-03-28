#!/bin/bash
# 最简单的工具查找器

TOOL_MAP_FILE="tool_keyword_map.md"
keyword="$1"

if [[ -z "$keyword" ]]; then
    echo "用法: $0 <关键词>"
    exit 1
fi

echo "搜索关键词: '$keyword'"

# 查找工具（跳过注释行）
results=$(grep -v '^#' "$TOOL_MAP_FILE" | grep -v '^$' | grep -i "$keyword" 2>/dev/null || true)

if [[ -z "$results" ]]; then
    echo "未找到匹配 '$keyword' 的工具"
    exit 1
fi

count=$(echo "$results" | wc -l)
echo "找到 $count 个匹配的工具"
echo ""
echo "=== 找到以下工具 ==="
echo ""

# 显示结果
echo "$results" | while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # 解析并显示
        tool_type=$(echo "$line" | cut -d':' -f1)
        tool_name=$(echo "$line" | cut -d':' -f2 | cut -d'|' -f1 | xargs)
        keywords=$(echo "$line" | cut -d'|' -f2 | xargs)
        command=$(echo "$line" | cut -d'|' -f3 | xargs)
        priority=$(echo "$line" | cut -d'|' -f4 | xargs)
        
        echo "工具类型: $tool_type"
        echo "工具名称: $tool_name"
        echo "关键词: $keywords"
        echo "命令示例: $command"
        echo "优先级: $priority"
        echo ""
    fi
done