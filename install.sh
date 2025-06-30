#!/bin/bash

# Git 同步工具一鍵安裝腳本
# 版本：2.1
# 用途：自動安裝和配置 Git 同步工具

# 顏色代碼
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 安裝配置
INSTALL_DIR="${1:-$(pwd)}"
REQUIRED_FILES=("git_sync.sh" "remote_config.sh" "security_check.sh" "test_git_sync.sh")
OPTIONAL_FILES=("README.md")

# 顯示標題
show_header() {
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}       Git 同步工具 v2.1 一鍵安裝器${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo ""
}

# 檢查系統需求
check_requirements() {
    echo -e "${BLUE}檢查系統需求...${NC}"

    # 檢查 Bash 版本
    local bash_version="${BASH_VERSION%%.*}"
    if [ "$bash_version" -ge 4 ]; then
        echo -e "${GREEN}✓ Bash 版本 $BASH_VERSION（支援關聯陣列）${NC}"
    else
        echo -e "${RED}✗ Bash 版本過舊：$BASH_VERSION（需要 4.0+）${NC}"
        echo -e "${YELLOW}請升級 Bash 版本後重試${NC}"
        exit 1
    fi

    # 檢查 Git
    if command -v git >/dev/null 2>&1; then
        local git_version=$(git --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
        echo -e "${GREEN}✓ Git 版本 $git_version${NC}"
    else
        echo -e "${RED}✗ 未安裝 Git${NC}"
        echo -e "${YELLOW}請先安裝 Git：https://git-scm.com/downloads${NC}"
        exit 1
    fi

    # 檢查必要命令
    local required_commands=("grep" "awk" "sed" "head" "tail" "wc")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ 所有必要命令都可用${NC}"
    else
        echo -e "${RED}✗ 缺少命令：${missing_commands[*]}${NC}"
        exit 1
    fi

    echo ""
}

# 檢查檔案完整性
check_files() {
    echo -e "${BLUE}檢查檔案完整性...${NC}"

    local missing_files=()

    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$INSTALL_DIR/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ 所有必要檔案都存在${NC}"
    else
        echo -e "${RED}✗ 缺少檔案：${missing_files[*]}${NC}"
        echo -e "${YELLOW}請確保所有檔案都在 $INSTALL_DIR 目錄中${NC}"
        exit 1
    fi

    # 檢查語法
    echo -e "${BLUE}檢查腳本語法...${NC}"
    local syntax_errors=0

    for file in "${REQUIRED_FILES[@]}"; do
        if ! bash -n "$INSTALL_DIR/$file" 2>/dev/null; then
            echo -e "${RED}✗ $file 語法錯誤${NC}"
            ((syntax_errors++))
        else
            echo -e "${GREEN}✓ $file 語法正確${NC}"
        fi
    done

    if [ "$syntax_errors" -gt 0 ]; then
        echo -e "${RED}發現 $syntax_errors 個語法錯誤，請修正後重試${NC}"
        exit 1
    fi

    echo ""
}

# 設置檔案權限
set_permissions() {
    echo -e "${BLUE}設置檔案權限...${NC}"

    for file in "${REQUIRED_FILES[@]}"; do
        if chmod +x "$INSTALL_DIR/$file" 2>/dev/null; then
            echo -e "${GREEN}✓ $file 設置為可執行${NC}"
        else
            echo -e "${RED}✗ 無法設置 $file 權限${NC}"
            exit 1
        fi
    done

    echo ""
}

# 運行測試
run_tests() {
    echo -e "${BLUE}運行安裝測試...${NC}"

    if [ -f "$INSTALL_DIR/test_git_sync.sh" ]; then
        cd "$INSTALL_DIR"

        if ./test_git_sync.sh >/dev/null 2>&1; then
            echo -e "${GREEN}✓ 所有測試通過${NC}"
        else
            echo -e "${YELLOW}⚠ 部分測試失敗，但安裝可以繼續${NC}"
            echo -e "${YELLOW}建議稍後執行：./test_git_sync.sh${NC}"
        fi

        cd - >/dev/null
    else
        echo -e "${YELLOW}⚠ 測試腳本不存在，跳過測試${NC}"
    fi

    echo ""
}

# 創建符號連結（可選）
create_symlinks() {
    echo -e "${BLUE}是否要創建全域符號連結？(y/n)${NC}"
    read -r create_links

    if [ "$create_links" = "y" ] || [ "$create_links" = "Y" ]; then
        local bin_dir="$HOME/bin"

        # 創建 bin 目錄
        if [ ! -d "$bin_dir" ]; then
            mkdir -p "$bin_dir"
            echo -e "${GREEN}✓ 創建目錄：$bin_dir${NC}"
        fi

        # 創建符號連結
        for file in "${REQUIRED_FILES[@]}"; do
            local source_file="$INSTALL_DIR/$file"
            local target_file="$bin_dir/$file"

            if [ -L "$target_file" ]; then
                rm "$target_file"
            fi

            if ln -s "$source_file" "$target_file" 2>/dev/null; then
                echo -e "${GREEN}✓ 創建連結：$target_file${NC}"
            else
                echo -e "${YELLOW}⚠ 無法創建連結：$target_file${NC}"
            fi
        done

        # 檢查 PATH
        if echo "$PATH" | grep -q "$bin_dir"; then
            echo -e "${GREEN}✓ $bin_dir 已在 PATH 中${NC}"
        else
            echo -e "${YELLOW}建議將以下行加入您的 shell 配置檔案：${NC}"
            echo -e "${CYAN}export PATH=\"\$HOME/bin:\$PATH\"${NC}"
        fi
    fi

    echo ""
}

# 顯示使用說明
show_usage() {
    echo -e "${BLUE}安裝完成！使用說明：${NC}"
    echo ""
    echo -e "${YELLOW}基本使用：${NC}"
    echo "  cd 到您的 Git 倉庫目錄"
    echo "  執行：$INSTALL_DIR/git_sync.sh"
    echo ""
    echo -e "${YELLOW}常用命令：${NC}"
    echo "  $INSTALL_DIR/git_sync.sh --version    # 查看版本"
    echo "  $INSTALL_DIR/git_sync.sh --help       # 顯示幫助"
    echo "  $INSTALL_DIR/git_sync.sh --debug      # 調試模式"
    echo "  $INSTALL_DIR/test_git_sync.sh          # 運行測試"
    echo ""
    echo -e "${YELLOW}功能特色：${NC}"
    echo "  • 雙平台同步（GitLab + GitHub）"
    echo "  • 20+ 種機密資訊檢測"
    echo "  • 自動生成環境變數範本"
    echo "  • 智慧遠端配置管理"
    echo ""
    echo -e "${GREEN}開始使用：${NC}"
    echo "  cd your-git-repo"
    echo "  $INSTALL_DIR/git_sync.sh"
    echo ""
}

# 顯示錯誤處理建議
show_troubleshooting() {
    echo -e "${BLUE}故障排除：${NC}"
    echo ""
    echo -e "${YELLOW}如果遇到問題：${NC}"
    echo "  1. 執行測試：$INSTALL_DIR/test_git_sync.sh"
    echo "  2. 查看調試：$INSTALL_DIR/git_sync.sh --debug"
    echo "  3. 檢查權限：ls -la $INSTALL_DIR/*.sh"
    echo "  4. 驗證 Bash：bash --version"
    echo ""
    echo -e "${YELLOW}常見問題：${NC}"
    echo "  • 權限錯誤：chmod +x $INSTALL_DIR/*.sh"
    echo "  • 語法錯誤：確保使用 Bash 4.0+"
    echo "  • 模組錯誤：確保所有檔案在同一目錄"
    echo ""
}

# 主安裝函數
main() {
    show_header

    echo -e "${BLUE}安裝目錄：${YELLOW}$INSTALL_DIR${NC}"
    echo ""

    # 檢查安裝目錄
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}安裝目錄不存在：$INSTALL_DIR${NC}"
        exit 1
    fi

    # 執行安裝步驟
    check_requirements
    check_files
    set_permissions
    run_tests
    create_symlinks

    echo -e "${GREEN}🎉 安裝成功完成！${NC}"
    echo ""

    show_usage
    show_troubleshooting

    echo -e "${CYAN}感謝使用 Git 同步工具！${NC}"
}

# 顯示幫助
show_help() {
    echo -e "${BLUE}Git 同步工具安裝器使用說明：${NC}"
    echo ""
    echo -e "${YELLOW}用途：${NC}自動安裝和配置 Git 同步工具"
    echo ""
    echo -e "${YELLOW}使用方法：${NC}"
    echo "  ./install.sh [安裝目錄]"
    echo ""
    echo -e "${YELLOW}參數：${NC}"
    echo "  安裝目錄    指定安裝目錄（預設：當前目錄）"
    echo ""
    echo -e "${YELLOW}選項：${NC}"
    echo "  -h, --help  顯示此說明"
    echo ""
    echo -e "${YELLOW}範例：${NC}"
    echo "  ./install.sh                    # 在當前目錄安裝"
    echo "  ./install.sh /opt/git-sync      # 在指定目錄安裝"
    echo "  ./install.sh --help             # 顯示說明"
}

# 處理命令列參數
case "$1" in
-h | --help)
    show_help
    exit 0
    ;;
*)
    main
    ;;
esac
