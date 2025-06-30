#!/bin/bash

# 主要的 GitLab 和 GitHub 倉庫檢查與同步腳本
# 作者：AI Assistant
# 版本：2.1（格式化優化版本）

# 腳本目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 顏色代碼
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 調試模式（設為 true 來啟用調試訊息）
DEBUG=false

# 調試函數
debug_log() {
    if [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[DEBUG] $1${NC}" >&2
    fi
}

# 檢查並載入模組
load_modules() {
    debug_log "開始載入模組..."

    # 檢查模組檔案是否存在
    local required_modules=("remote_config.sh" "security_check.sh")

    for module in "${required_modules[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$module" ]; then
            echo -e "${RED}錯誤：找不到模組檔案 $module${NC}"
            echo -e "${YELLOW}請確保 $module 與主腳本在同一目錄中${NC}"
            return 1
        fi
    done

    # 載入模組
    debug_log "載入 remote_config.sh..."
    if ! source "$SCRIPT_DIR/remote_config.sh"; then
        echo -e "${RED}錯誤：載入 remote_config.sh 失敗${NC}"
        return 1
    fi

    debug_log "載入 security_check.sh..."
    if ! source "$SCRIPT_DIR/security_check.sh"; then
        echo -e "${RED}錯誤：載入 security_check.sh 失敗${NC}"
        return 1
    fi

    debug_log "模組載入完成"
    return 0
}

# 處理單平台情況
handle_single_platform() {
    local existing_remote="$1"
    local platform_name="$2"
    local current_branch="$3"

    echo ""
    echo -e "${YELLOW}檢測到您只配置了 $platform_name 遠端。${NC}"
    echo -e "${YELLOW}您可以選擇：${NC}"
    echo "1) 直接推送到 $platform_name"
    echo "2) 配置第二個平台以啟用雙平台同步"
    echo "3) 取消操作"

    read -p "請選擇 (1-3): " platform_choice

    case $platform_choice in
    1)
        echo -e "${BLUE}執行單平台推送到 $platform_name...${NC}"

        # 執行安全檢查
        echo -e "${PURPLE}================== 安全檢查 ==================${NC}"
        if ! perform_security_check; then
            if ! handle_security_issues; then
                echo -e "${RED}腳本已終止。${NC}"
                return 1
            fi
        fi
        echo -e "${PURPLE}=============================================${NC}"
        echo ""

        # 推送到單個平台
        push_to_single_platform "$existing_remote" "$platform_name" "$current_branch"
        ;;
    2)
        echo -e "${BLUE}開始配置第二個平台...${NC}"
        configure_second_platform "$platform_name" "$existing_remote" "$current_branch"
        ;;
    3)
        echo -e "${YELLOW}操作已取消。${NC}"
        return 1
        ;;
    *)
        echo -e "${RED}無效的選項，操作已取消。${NC}"
        return 1
        ;;
    esac
}

# 推送到單個平台
push_to_single_platform() {
    local remote="$1"
    local platform="$2"
    local branch="$3"

    echo -e "${YELLOW}推送到 $platform (${remote})...${NC}"

    if [ ! -z "$branch" ]; then
        git push "$remote" "$branch"
    else
        git push "$remote"
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功推送到 $platform${NC}"
    else
        echo -e "${RED}✗ 推送到 $platform 失敗${NC}"
    fi
}

# 配置第二個平台
configure_second_platform() {
    local platform_name="$1"
    local existing_remote="$2"
    local current_branch="$3"

    if [ "$platform_name" = "GitLab" ]; then
        prompt_add_github_remote
        local new_github=$(get_github_remote)
        if [ ! -z "$new_github" ]; then
            setup_all_remote "$existing_remote" "$new_github"
            perform_dual_platform_sync "$current_branch"
        fi
    else
        prompt_add_gitlab_remote
        local new_gitlab=$(get_gitlab_remote)
        if [ ! -z "$new_gitlab" ]; then
            setup_all_remote "$new_gitlab" "$existing_remote"
            perform_dual_platform_sync "$current_branch"
        fi
    fi
}

# 執行雙平台同步
perform_dual_platform_sync() {
    local current_branch="$1"

    echo -e "${PURPLE}================== 安全檢查 ==================${NC}"
    if ! perform_security_check; then
        if ! handle_security_issues; then
            echo -e "${RED}腳本已終止。${NC}"
            return 1
        fi
    fi
    echo -e "${PURPLE}=============================================${NC}"
    echo ""

    perform_push "$current_branch"
}

# 執行推送函數
perform_push() {
    local current_branch="$1"

    # 如果沒有提供分支名，使用當前分支
    if [ -z "$current_branch" ]; then
        current_branch=$(git branch --show-current)
    fi

    echo -e "${YELLOW}是否現在要推送到兩個倉庫？(y/n)${NC}"
    read push_now

    if [ "$push_now" = "y" ] || [ "$push_now" = "Y" ]; then
        if git remote -v | grep -q "all"; then
            push_via_all_remote "$current_branch"
        else
            individual_push "$current_branch"
        fi
    else
        echo -e "${YELLOW}推送已取消。${NC}"
    fi
}

# 通過 'all' 遠端推送
push_via_all_remote() {
    local current_branch="$1"

    echo -e "${YELLOW}通過 'all' 遠端推送到兩個倉庫...${NC}"

    if [ ! -z "$current_branch" ]; then
        git push all "$current_branch"
    else
        git push all
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功推送到兩個倉庫${NC}"
    else
        echo -e "${RED}✗ 推送到兩個倉庫失敗${NC}"
        fallback_individual_push "$current_branch"
    fi
}

# 個別推送函數
individual_push() {
    local current_branch="$1"
    local gitlab_remote=$(get_gitlab_remote)
    local github_remote=$(get_github_remote)

    if [ ! -z "$gitlab_remote" ]; then
        echo -e "${YELLOW}推送到 GitLab (${gitlab_remote})...${NC}"
        if [ ! -z "$current_branch" ]; then
            git push "$gitlab_remote" "$current_branch"
        else
            git push "$gitlab_remote"
        fi

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 成功推送到 GitLab${NC}"
        else
            echo -e "${RED}✗ 推送到 GitLab 失敗${NC}"
        fi
    fi

    if [ ! -z "$github_remote" ]; then
        echo -e "${YELLOW}推送到 GitHub (${github_remote})...${NC}"
        if [ ! -z "$current_branch" ]; then
            git push "$github_remote" "$current_branch"
        else
            git push "$github_remote"
        fi

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 成功推送到 GitHub${NC}"
        else
            echo -e "${RED}✗ 推送到 GitHub 失敗${NC}"
        fi
    fi
}

# 備用個別推送函數
fallback_individual_push() {
    local current_branch="$1"

    echo -e "${YELLOW}嘗試單獨推送...${NC}"
    individual_push "$current_branch"
}

# 主函數
main() {
    debug_log "主函數開始執行"

    echo -e "${CYAN}==================== Git 同步工具 ====================${NC}"
    echo -e "${YELLOW}版本：2.1（格式化優化版本）${NC}"
    echo ""

    # 載入模組
    if ! load_modules; then
        echo -e "${RED}模組載入失敗，腳本終止${NC}"
        exit 1
    fi

    # 檢查當前目錄是否為 git 倉庫
    debug_log "檢查 Git 倉庫"
    if [ ! -d ".git" ]; then
        echo -e "${RED}錯誤：當前目錄不是 Git 倉庫。${NC}"
        exit 1
    fi

    # 配置遠端倉庫
    echo -e "${PURPLE}================== 遠端配置檢查 ==================${NC}"
    if ! configure_remotes; then
        echo -e "${RED}遠端配置失敗${NC}"
        exit 1
    fi

    # 獲取配置結果
    local gitlab_remote=$(get_gitlab_remote)
    local github_remote=$(get_github_remote)

    debug_log "GitLab 遠端: $gitlab_remote"
    debug_log "GitHub 遠端: $github_remote"

    # 獲取當前分支
    local current_branch=$(git branch --show-current)
    echo -e "${YELLOW}當前分支: ${current_branch}${NC}"
    echo ""

    # 檢查遠端配置狀況並執行相應操作
    process_remote_configuration "$gitlab_remote" "$github_remote" "$current_branch"

    echo -e "${GREEN}腳本執行完成。${NC}"
}

# 處理遠端配置
process_remote_configuration() {
    local gitlab_remote="$1"
    local github_remote="$2"
    local current_branch="$3"

    if [ ! -z "$gitlab_remote" ] && [ ! -z "$github_remote" ]; then
        # 雙平台配置
        echo -e "${GREEN}✓ 檢測到 GitLab 和 GitHub 雙平台配置${NC}"
        setup_all_remote "$gitlab_remote" "$github_remote"

        # 執行安全檢查
        echo -e "${PURPLE}================== 安全檢查 ==================${NC}"
        if ! perform_security_check; then
            if ! handle_security_issues; then
                echo -e "${RED}腳本已終止。${NC}"
                exit 1
            fi
        fi
        echo -e "${PURPLE}=============================================${NC}"
        echo ""

        # 執行推送
        perform_push "$current_branch"

    elif [ ! -z "$gitlab_remote" ] && [ -z "$github_remote" ]; then
        # 僅 GitLab
        echo -e "${YELLOW}僅檢測到 GitLab 遠端，是否需要添加 GitHub 遠端以啟用雙平台同步？${NC}"
        handle_single_platform "$gitlab_remote" "GitLab" "$current_branch"

    elif [ -z "$gitlab_remote" ] && [ ! -z "$github_remote" ]; then
        # 僅 GitHub
        echo -e "${YELLOW}僅檢測到 GitHub 遠端，是否需要添加 GitLab 遠端以啟用雙平台同步？${NC}"
        handle_single_platform "$github_remote" "GitHub" "$current_branch"

    else
        # 無有效配置
        echo -e "${RED}錯誤：未檢測到任何有效的遠端配置${NC}"
        echo -e "${YELLOW}請先配置 GitLab 或 GitHub 遠端，然後重新執行腳本${NC}"
        exit 1
    fi
}

# 顯示使用說明
show_usage() {
    echo -e "${BLUE}Git 同步工具使用說明：${NC}"
    echo ""
    echo -e "${YELLOW}功能：${NC}"
    echo "  - 自動檢測和配置 GitLab 與 GitHub 遠端"
    echo "  - 安全檢查，防止機密資訊洩露"
    echo "  - 支援同時推送到多個遠端倉庫"
    echo "  - 環境變數範本自動生成"
    echo ""
    echo -e "${YELLOW}使用方法：${NC}"
    echo "  ./git_sync.sh [選項]"
    echo ""
    echo -e "${YELLOW}選項：${NC}"
    echo "  -h, --help     顯示此說明"
    echo "  -v, --version  顯示版本資訊"
    echo "  -d, --debug    啟用調試模式"
    echo ""
    echo -e "${YELLOW}需要的模組檔案：${NC}"
    echo "  - remote_config.sh    (遠端配置模組)"
    echo "  - security_check.sh   (安全檢查模組)"
    echo ""
    echo -e "${YELLOW}範例：${NC}"
    echo "  ./git_sync.sh          # 互動式同步"
    echo "  ./git_sync.sh --debug  # 調試模式"
    echo "  ./git_sync.sh --help   # 顯示說明"
}

# 顯示版本資訊
show_version() {
    echo "Git 同步工具 v2.1（格式化優化版本）"
    echo "作者：AI Assistant"
    echo "支援平台：GitLab, GitHub"
    echo "新功能：環境變數範本生成、進階安全檢查"
}

# 處理命令列參數
handle_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_usage
            exit 0
            ;;
        -v | --version)
            show_version
            exit 0
            ;;
        -d | --debug)
            DEBUG=true
            debug_log "調試模式已啟用"
            shift
            ;;
        *)
            echo -e "${RED}未知的選項: $1${NC}"
            echo -e "${YELLOW}使用 --help 查看可用選項${NC}"
            exit 1
            ;;
        esac
    done
}

# 主程式入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 處理命令列參數
    handle_arguments "$@"

    # 執行主函數
    main
fi
