#!/bin/bash

# 主要的 GitLab 和 GitHub 倉庫檢查與同步腳本
# 作者：AI Assistant
# 版本：2.0（模組化版本）

# 腳本目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 顏色代碼
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    if [ ! -f "$SCRIPT_DIR/remote_config.sh" ]; then
        echo -e "${RED}錯誤：找不到模組檔案 remote_config.sh${NC}"
        echo -e "${YELLOW}請確保 remote_config.sh 與主腳本在同一目錄中${NC}"
        return 1
    fi
    
    if [ ! -f "$SCRIPT_DIR/security_check.sh" ]; then
        echo -e "${RED}錯誤：找不到模組檔案 security_check.sh${NC}"
        echo -e "${YELLOW}請確保 security_check.sh 與主腳本在同一目錄中${NC}"
        return 1
    fi
    
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

# 主函數
main() {
    debug_log "主函數開始執行"
    
    echo -e "${BLUE}==================== Git 同步工具 ====================${NC}"
    echo -e "${YELLOW}版本：2.0（模組化版本）${NC}"
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
    GITLAB_REMOTE=$(get_gitlab_remote)
    GITHUB_REMOTE=$(get_github_remote)
    
    debug_log "GitLab 遠端: $GITLAB_REMOTE"
    debug_log "GitHub 遠端: $GITHUB_REMOTE"
    
    # 獲取當前分支
    CURRENT_BRANCH=$(git branch --show-current)
    echo -e "${YELLOW}當前分支: ${CURRENT_BRANCH}${NC}"
    echo ""
    
    # 如果兩個遠端都配置好了
    if [ ! -z "$GITLAB_REMOTE" ] && [ ! -z "$GITHUB_REMOTE" ]; then
        # 設置合併遠端
        setup_all_remote "$GITLAB_REMOTE" "$GITHUB_REMOTE"
        
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
        perform_push "$CURRENT_BRANCH"
    else
        echo -e "${YELLOW}請確保 GitLab 和 GitHub 遠端都已正確配置。${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}腳本執行完成。${NC}"
}

# 執行推送函數
perform_push() {
    local current_branch="$1"
    
    echo -e "${YELLOW}是否現在要推送到兩個倉庫？(y/n)${NC}"
    read push_now
    
    if [ "$push_now" = "y" ] || [ "$push_now" = "Y" ]; then
        if git remote -v | grep -q "all"; then
            echo -e "${YELLOW}通過 'all' 遠端推送到兩個倉庫...${NC}"
            git push all "$current_branch"
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ 成功推送到兩個倉庫${NC}"
            else
                echo -e "${RED}✗ 推送到兩個倉庫失敗${NC}"
                fallback_individual_push "$current_branch"
            fi
        else
            individual_push "$current_branch"
        fi
    fi
}

# 個別推送函數
individual_push() {
    local current_branch="$1"
    local gitlab_remote=$(get_gitlab_remote)
    local github_remote=$(get_github_remote)
    
    if [ ! -z "$gitlab_remote" ]; then
        echo -e "${YELLOW}推送到 GitLab (${gitlab_remote})...${NC}"
        git push "$gitlab_remote" "$current_branch"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 成功推送到 GitLab${NC}"
        else
            echo -e "${RED}✗ 推送到 GitLab 失敗${NC}"
        fi
    fi
    
    if [ ! -z "$github_remote" ]; then
        echo -e "${YELLOW}推送到 GitHub (${github_remote})...${NC}"
        git push "$github_remote" "$current_branch"
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

# 顯示使用說明
show_usage() {
    echo -e "${BLUE}Git 同步工具使用說明：${NC}"
    echo ""
    echo -e "${YELLOW}功能：${NC}"
    echo "  - 自動檢測和配置 GitLab 與 GitHub 遠端"
    echo "  - 安全檢查，防止機密資訊洩露"
    echo "  - 支援同時推送到多個遠端倉庫"
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
}

# 顯示版本資訊
show_version() {
    echo "Git 同步工具 v2.0（模組化版本）"
    echo "作者：AI Assistant"
    echo "支援平台：GitLab, GitHub"
}

# 處理命令列參數
handle_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--debug)
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