#!/bin/bash
# tool_finder.sh - 工具查找器
# 根据关键词查找合适的工具命令

set -euo pipefail

# 配置文件
TOOL_MAP_FILE="$(dirname "$0")/tool_keyword_map.md"
SCRIPT_NAME="tool_finder.sh"
VERSION="1.0.0"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
RESET='\033[0m'

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local color="$RESET"
    
    case "$level" in
        "ERROR")   color="$RED" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO")    color="$GREEN" ;;
        "DEBUG")   color="$CYAN" ;;
    esac
    
    echo -e "${color}[${level}] ${message}${RESET}" >&2
}

# 显示帮助
show_help() {
    cat << EOF
${SCRIPT_NAME} - 工具查找器 v${VERSION}

根据关键词查找合适的工具命令。

用法: ${SCRIPT_NAME} [选项] <关键词>

选项:
  -h, --help          显示此帮助信息
  -v, --verbose       详细输出模式
  -a, --all           显示所有匹配结果（默认只显示前5个）
  -t, --type TYPE     按工具类型过滤 (bash/python/all)
  -p, --priority      按优先级排序（高优先级在前）
  -e, --execute       直接执行找到的第一个命令（谨慎使用）
  -c, --copy          复制命令到剪贴板（需要xclip或pbcopy）
  --version           显示版本信息

示例:
  ${SCRIPT_NAME} 目录
  ${SCRIPT_NAME} -t bash 文件
  ${SCRIPT_NAME} -a 统计
  ${SCRIPT_NAME} -p 搜索
  ${SCRIPT_NAME} -e 时间  # 直接执行date命令

工具类型:
  bash    - Shell命令
  python  - Python代码
  all     - 所有工具（默认）
EOF
}

# 查找工具
find_tools() {
    local keyword="$1"
    local tool_type="${2:-all}"
    local show_all="${3:-false}"
    local sort_priority="${4:-false}"
    
    log "INFO" "搜索关键词: '$keyword'"
    
    # 检查映射文件是否存在
    if [[ ! -f "$TOOL_MAP_FILE" ]]; then
        log "ERROR" "工具映射文件不存在: $TOOL_MAP_FILE"
        return 1
    fi
    
    # 读取映射文件（跳过注释和空行）
    local map_content
    map_content=$(grep -v '^#' "$TOOL_MAP_FILE" | grep -v '^$')
    
    # 构建搜索命令
    local search_results
    if [[ "$tool_type" == "all" ]]; then
        search_results=$(echo "$map_content" | grep -i "$keyword")
    else
        search_results=$(echo "$map_content" | grep -i "^$tool_type:" | grep -i "$keyword")
    fi
    
    # 按优先级排序
    if [[ "$sort_priority" == "true" ]]; then
        search_results=$(echo "$search_results" | sort -t'|' -k4 -rn)
    fi
    
    # 限制结果数量
    if [[ "$show_all" == "false" ]]; then
        search_results=$(echo "$search_results" | head -5)
    fi
    
    local result_count=$(echo "$search_results" | wc -l)
    
    if [[ $result_count -eq 0 ]]; then
        log "WARNING" "未找到匹配 '$keyword' 的工具"
        return 1
    else
        log "INFO" "找到 $result_count 个匹配的工具"
        echo "$search_results"
        return 0
    fi
}

# 显示工具详情
show_tool_detail() {
    local tool_line="$1"
    
    # 解析工具行
    local tool_type=$(echo "$tool_line" | cut -d':' -f1)
    local tool_name=$(echo "$tool_line" | cut -d':' -f2 | cut -d'|' -f1 | xargs)
    local keywords=$(echo "$tool_line" | cut -d'|' -f2 | xargs)
    local command=$(echo "$tool_line" | cut -d'|' -f3 | xargs)
    local priority=$(echo "$tool_line" | cut -d'|' -f4 | xargs)
    
    echo -e "${CYAN}工具类型:${RESET} $tool_type"
    echo -e "${CYAN}工具名称:${RESET} $tool_name"
    echo -e "${CYAN}关键词:${RESET} $keywords"
    echo -e "${CYAN}命令示例:${RESET} $command"
    echo -e "${CYAN}优先级:${RESET} $priority"
    echo ""
}

# 执行命令
execute_command() {
    local tool_line="$1"
    local command=$(echo "$tool_line" | cut -d'|' -f3 | xargs)
    
    log "WARNING" "即将执行命令: $command"
    read -p "是否确认执行？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "执行命令..."
        eval "$command"
    else
        log "INFO" "取消执行"
    fi
}

# 复制命令到剪贴板
copy_to_clipboard() {
    local tool_line="$1"
    local command=$(echo "$tool_line" | cut -d'|' -f3 | xargs)
    
    # 检查系统剪贴板工具
    if command -v xclip >/dev/null 2>&1; then
        echo -n "$command" | xclip -selection clipboard
        log "INFO" "命令已复制到剪贴板 (xclip)"
    elif command -v pbcopy >/dev/null 2>&1; then
        echo -n "$command" | pbcopy
        log "INFO" "命令已复制到剪贴板 (pbcopy)"
    else
        log "ERROR" "未找到剪贴板工具 (xclip或pbcopy)"
        echo "命令: $command"
    fi
}

# 主函数
main() {
    local keyword=""
    local tool_type="all"
    local verbose=false
    local show_all=false
    local sort_priority=false
    local execute=false
    local copy=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -a|--all)
                show_all=true
                shift
                ;;
            -t|--type)
                tool_type="$2"
                shift 2
                ;;
            -p|--priority)
                sort_priority=true
                shift
                ;;
            -e|--execute)
                execute=true
                shift
                ;;
            -c|--copy)
                copy=true
                shift
                ;;
            --version)
                echo "${SCRIPT_NAME} v${VERSION}"
                exit 0
                ;;
            -*)
                log "ERROR" "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                keyword="$1"
                shift
                ;;
        esac
    done
    
    # 检查关键词
    if [[ -z "$keyword" ]]; then
        log "ERROR" "请提供搜索关键词"
        show_help
        exit 1
    fi
    
    # 查找工具
    log "INFO" "开始查找工具..."
    
    local search_results
    if ! search_results=$(find_tools "$keyword" "$tool_type" "$show_all" "$sort_priority"); then
        # 尝试模糊搜索
        log "INFO" "尝试模糊搜索..."
        
        # 将关键词拆分为多个词
        IFS=' ' read -ra words <<< "$keyword"
        for word in "${words[@]}"; do
            if [[ ${#word} -gt 2 ]]; then  # 只搜索长度大于2的词
                log "DEBUG" "尝试搜索子词: '$word'"
                if search_results=$(find_tools "$word" "$tool_type" "$show_all" "$sort_priority"); then
                    break
                fi
            fi
        done
        
        if [[ -z "$search_results" ]]; then
            log "ERROR" "无法找到匹配的工具，请尝试其他关键词"
            exit 1
        fi
    fi
    
    # 显示结果
    echo ""
    echo -e "${GREEN}=== 找到以下工具 ===${RESET}"
    echo ""
    
    local count=0
    while IFS= read -r line; do
        ((count++))
        echo -e "${BLUE}[$count]${RESET}"
        show_tool_detail "$line"
        
        # 如果只需要执行或复制，处理第一个结果后退出
        if [[ $count -eq 1 ]]; then
            if [[ "$execute" == "true" ]]; then
                execute_command "$line"
                exit 0
            elif [[ "$copy" == "true" ]]; then
                copy_to_clipboard "$line"
                exit 0
            fi
        fi
    done <<< "$search_results"
    
    # 如果详细模式，显示统计信息
    if [[ "$verbose" == "true" ]]; then
        echo ""
        echo -e "${GREEN}=== 搜索统计 ===${RESET}"
        echo "关键词: $keyword"
        echo "工具类型: $tool_type"
        echo "显示数量: $count"
        echo "排序方式: $( [[ "$sort_priority" == "true" ]] && echo "按优先级" || echo "默认" )"
        echo ""
    fi
    
    # 提示用户选择
    if [[ $count -gt 1 ]] && [[ "$execute" == "false" ]] && [[ "$copy" == "false" ]]; then
        echo -e "${YELLOW}提示:${RESET} 使用 ${CYAN}-e${RESET} 选项直接执行第一个命令，或 ${CYAN}-c${RESET} 复制到剪贴板"
    fi
    
    exit 0
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi