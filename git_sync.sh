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

# 匯入模組函數
source "$SCRIPT_DIR/remote_config.sh"
source "$SCRIPT_DIR/security_check.sh"

# 主函數
main() {
    echo -e "${BLUE}==================== Git 同步工具 ====================${NC}"
    echo -e "${YELLOW}版本：2.0（模組化版本）${NC}"
    echo ""
    
    # 檢查當前目錄是否為 git 倉庫
    if [ ! -d ".git" ]; then
        echo -e "${RED}錯誤：當前目錄不是 Git 倉庫。${NC}"
        exit 1
    fi
    
    # 配置遠端倉庫
    echo -e "${PURPLE}================== 遠端配置檢查 ==================${NC}"
    configure_remotes
    
    # 獲取配置結果
    GITLAB_REMOTE=$(get_gitlab_remote)
    GITHUB_REMOTE=$(get_github_remote)
    
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

# 檢查依賴模組是否存在
check_dependencies() {
    local missing_modules=()
    
    if [ ! -f "$SCRIPT_DIR/remote_config.sh" ]; then
        missing_modules+=("remote_config.sh")
    fi
    
    if [ ! -f "$SCRIPT_DIR/security_check.sh" ]; then
        missing_modules+=("security_check.sh")
    fi
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        echo -e "${RED}錯誤：缺少必要的模組檔案：${NC}"
        for module in "${missing_modules[@]}"; do
            echo -e "${RED}  - $module${NC}"
        done
        echo -e "${YELLOW}請確保所有模組檔案都在同一目錄中。${NC}"
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
    echo ""
    echo -e "${YELLOW}使用方法：${NC}"
    echo "  ./git_sync.sh [選項]"
    echo ""
    echo -e "${YELLOW}選項：${NC}"
    echo "  -h, --help     顯示此說明"
    echo "  -v, --version  顯示版本資訊"
    echo ""
    echo -e "${YELLOW}需要的模組檔案：${NC}"
    echo "  - remote_config.sh    (遠端配置模組)"
    echo "  - security_check.sh   (安全檢查模組)"
}

# 處理命令列參數
case "$1" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -v|--version)
        echo "Git 同步工具 v2.0（模組化版本）"
        exit 0
        ;;
    *)
        # 檢查依賴模組
        check_dependencies
        
        # 執行主函數
        main
        ;;
esac