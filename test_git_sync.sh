#!/bin/bash

# Git 同步工具完整測試腳本
# 版本：2.1
# 用途：全面測試 git_sync.sh 的所有功能

# 顏色代碼
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 測試計數器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 測試結果記錄
declare -a TEST_RESULTS
declare -a WARNINGS

# 腳本目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 測試輔助函數
test_start() {
    echo -e "${CYAN}[測試] $1${NC}"
    ((TOTAL_TESTS++))
}

test_pass() {
    echo -e "${GREEN}  ✓ 通過${NC}"
    ((PASSED_TESTS++))
    TEST_RESULTS+=("✓ $1")
}

test_fail() {
    echo -e "${RED}  ✗ 失敗: $1${NC}"
    ((FAILED_TESTS++))
    TEST_RESULTS+=("✗ $1")
}

test_warning() {
    echo -e "${YELLOW}  ⚠ 警告: $1${NC}"
    WARNINGS+=("⚠ $1")
}

test_info() {
    echo -e "${BLUE}  ℹ 資訊: $1${NC}"
}

# 測試環境檢查
test_environment() {
    echo -e "${PURPLE}==================== 環境檢查 ====================${NC}"

    # 檢查當前目錄
    test_start "檢查當前目錄"
    if [ -d ".git" ]; then
        test_pass "當前目錄是 Git 倉庫"
    else
        test_fail "當前目錄不是 Git 倉庫"
        return 1
    fi

    # 檢查 Bash 版本
    test_start "檢查 Bash 版本"
    local bash_major_version="${BASH_VERSION%%.*}"
    if [ "$bash_major_version" -ge 4 ]; then
        test_pass "Bash 版本 $BASH_VERSION 支援關聯陣列"
    else
        test_fail "Bash 版本過舊：$BASH_VERSION（需要 4.0+）"
    fi

    # 檢查 Git 版本
    test_start "檢查 Git 版本"
    local git_version=$(git --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    if [ ! -z "$git_version" ]; then
        test_pass "Git 版本：$git_version"
    else
        test_fail "無法檢測 Git 版本"
    fi

    # 檢查作業系統
    test_start "檢查作業系統"
    local os_info=$(uname -s 2>/dev/null)
    if [ ! -z "$os_info" ]; then
        test_pass "作業系統：$os_info"
    else
        test_warning "無法檢測作業系統"
    fi

    # 檢查必要命令
    test_start "檢查必要命令"
    local required_commands=("grep" "awk" "sed" "head" "tail" "wc")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -eq 0 ]; then
        test_pass "所有必要命令都可用"
    else
        test_fail "缺少命令: ${missing_commands[*]}"
    fi

    echo ""
}

# 測試檔案存在性和權限
test_files() {
    echo -e "${PURPLE}==================== 檔案檢查 ====================${NC}"

    local required_files=("git_sync.sh" "remote_config.sh" "security_check.sh")
    local optional_files=("README.md" "test_git_sync.sh")

    # 檢查必要檔案
    for file in "${required_files[@]}"; do
        test_start "檢查必要檔案：$file"

        if [ ! -f "$SCRIPT_DIR/$file" ]; then
            test_fail "檔案不存在"
            continue
        fi

        if [ ! -r "$SCRIPT_DIR/$file" ]; then
            test_fail "檔案不可讀"
            continue
        fi

        if [ ! -x "$SCRIPT_DIR/$file" ]; then
            test_warning "檔案不可執行（可能需要 chmod +x）"
        fi

        # 檢查檔案大小
        local file_size=$(wc -c <"$SCRIPT_DIR/$file" 2>/dev/null)
        if [ "$file_size" -gt 0 ]; then
            test_pass "檔案存在且可讀（$file_size 位元組）"
        else
            test_fail "檔案為空"
        fi
    done

    # 檢查可選檔案
    for file in "${optional_files[@]}"; do
        test_start "檢查可選檔案：$file"
        if [ -f "$SCRIPT_DIR/$file" ]; then
            test_info "檔案存在"
        else
            test_info "檔案不存在（可選）"
        fi
    done

    echo ""
}

# 測試語法檢查
test_syntax() {
    echo -e "${PURPLE}==================== 語法檢查 ====================${NC}"

    local scripts=("git_sync.sh" "remote_config.sh" "security_check.sh")

    for script in "${scripts[@]}"; do
        test_start "語法檢查：$script"

        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            test_fail "檔案不存在"
            continue
        fi

        local syntax_errors=$(bash -n "$SCRIPT_DIR/$script" 2>&1)
        if [ $? -eq 0 ]; then
            test_pass "語法正確"
        else
            test_fail "語法錯誤"
            echo -e "${RED}語法錯誤詳情：${NC}"
            echo "$syntax_errors" | head -10 # 只顯示前10行錯誤
        fi
    done

    echo ""
}

# 測試模組載入
test_module_loading() {
    echo -e "${PURPLE}==================== 模組載入測試 ====================${NC}"

    # 測試 remote_config.sh
    test_start "載入 remote_config.sh"
    if source "$SCRIPT_DIR/remote_config.sh" 2>/dev/null; then
        test_pass "模組載入成功"

        # 測試關鍵函數是否存在
        local required_functions=("configure_remotes" "get_gitlab_remote" "get_github_remote" "setup_all_remote")
        for func in "${required_functions[@]}"; do
            if declare -f "$func" >/dev/null 2>&1; then
                test_info "函數 $func 已定義"
            else
                test_warning "函數 $func 未找到"
            fi
        done
    else
        test_fail "模組載入失敗"
    fi

    # 測試 security_check.sh
    test_start "載入 security_check.sh"
    if source "$SCRIPT_DIR/security_check.sh" 2>/dev/null; then
        test_pass "模組載入成功"

        # 測試關鍵函數是否存在
        local required_functions=("perform_security_check" "handle_security_issues" "init_security_patterns")
        for func in "${required_functions[@]}"; do
            if declare -f "$func" >/dev/null 2>&1; then
                test_info "函數 $func 已定義"
            else
                test_warning "函數 $func 未找到"
            fi
        done

        # 測試安全模式初始化
        test_start "測試安全模式初始化"
        if init_security_patterns 2>/dev/null && [ ${#SECURITY_PATTERNS[@]} -gt 0 ]; then
            test_pass "安全模式初始化成功（${#SECURITY_PATTERNS[@]} 個模式）"
        else
            test_fail "安全模式初始化失敗"
        fi
    else
        test_fail "模組載入失敗"
    fi

    echo ""
}

# 測試主腳本基本功能
test_main_script() {
    echo -e "${PURPLE}==================== 主腳本測試 ====================${NC}"

    # 測試版本顯示
    test_start "測試 --version 參數"
    local version_output=$("$SCRIPT_DIR/git_sync.sh" --version 2>/dev/null)
    if echo "$version_output" | grep -q "Git 同步工具"; then
        test_pass "版本資訊顯示正常"
        test_info "版本：$(echo "$version_output" | head -1)"
    else
        test_fail "版本資訊顯示異常"
    fi

    # 測試幫助顯示
    test_start "測試 --help 參數"
    local help_output=$("$SCRIPT_DIR/git_sync.sh" --help 2>/dev/null)
    if echo "$help_output" | grep -q "使用說明"; then
        test_pass "幫助資訊顯示正常"
    else
        test_fail "幫助資訊顯示異常"
    fi

    # 測試無效參數處理
    test_start "測試無效參數處理"
    local invalid_output=$("$SCRIPT_DIR/git_sync.sh" --invalid-option 2>&1)
    if echo "$invalid_output" | grep -q "未知的選項"; then
        test_pass "無效參數正確處理"
    else
        test_fail "無效參數處理異常"
    fi

    # 測試調試模式
    test_start "測試 --debug 參數"
    local debug_output=$("$SCRIPT_DIR/git_sync.sh" --debug --version 2>&1)
    if echo "$debug_output" | grep -q "DEBUG"; then
        test_pass "調試模式正常啟用"
    else
        test_warning "調試模式可能未正常啟用"
    fi

    echo ""
}

# 測試 Git 配置分析
test_git_config() {
    echo -e "${PURPLE}==================== Git 配置分析 ====================${NC}"

    # 檢查當前 Git 遠端
    test_start "分析當前 Git 遠端配置"
    local remotes=$(git remote -v 2>/dev/null)

    if [ -z "$remotes" ]; then
        test_warning "沒有配置任何遠端"
        return
    fi

    test_pass "發現以下遠端配置："
    echo "$remotes" | while read line; do
        test_info "$line"
    done

    # 分析遠端類型
    local gitlab_count=$(echo "$remotes" | grep -c "gitlab" 2>/dev/null || echo "0")
    local github_count=$(echo "$remotes" | grep -c "github" 2>/dev/null || echo "0")

    test_start "遠端類型分析"
    if [ "$gitlab_count" -gt 0 ] && [ "$github_count" -gt 0 ]; then
        test_pass "檢測到 GitLab 和 GitHub 雙平台配置"
    elif [ "$gitlab_count" -gt 0 ]; then
        test_info "僅檢測到 GitLab 遠端"
    elif [ "$github_count" -gt 0 ]; then
        test_info "僅檢測到 GitHub 遠端"
    else
        test_warning "未檢測到 GitLab 或 GitHub 遠端"
    fi

    # 檢查 'all' 遠端配置
    test_start "檢查 'all' 遠端配置"
    if git remote | grep -q "^all$"; then
        local all_urls=$(git remote get-url --all --push all 2>/dev/null)
        local url_count=$(echo "$all_urls" | wc -l 2>/dev/null)

        if [ "$url_count" -gt 1 ]; then
            test_pass "'all' 遠端已配置（$url_count 個 URL）"
            echo "$all_urls" | while read url; do
                if echo "$url" | grep -q "gitlab"; then
                    test_info "GitLab: $url"
                elif echo "$url" | grep -q "github"; then
                    test_info "GitHub: $url"
                else
                    test_info "其他: $url"
                fi
            done
        else
            test_warning "'all' 遠端存在但只有一個 URL"
        fi
    else
        test_info "'all' 遠端未配置"
    fi

    # 檢查遠端 URL 格式
    test_start "檢查遠端 URL 格式"
    local problematic_urls=0
    while read -r remote_line; do
        local url=$(echo "$remote_line" | awk '{print $2}')
        if echo "$url" | grep -E "(gitlab|github)" | grep -v "\.git$" >/dev/null; then
            test_warning "URL 可能需要 .git 後綴: $url"
            ((problematic_urls++))
        fi
    done <<<"$remotes"

    if [ "$problematic_urls" -eq 0 ]; then
        test_pass "所有遠端 URL 格式正確"
    fi

    echo ""
}

# 測試安全檢查功能
test_security_check() {
    echo -e "${PURPLE}==================== 安全檢查測試 ====================${NC}"

    # 創建測試檔案
    test_start "創建測試檔案"
    local test_file="test_security_patterns.tmp"

    cat >"$test_file" <<'EOF'
# 測試用的安全模式檔案 (全部為假值，僅供測試偵測功能)
password=FAKE_PASSWORD_FOR_TESTING
api_key=FAKE_AKIAIOSFODNN7EXAMPLE
database_url=postgresql://fake_user:fake_pass@localhost/fake_db
email=fake_test@example.com
phone=0900000000
credit_card=0000 0000 0000 0000
private_key=-----BEGIN FAKE RSA PRIVATE KEY-----
github_token=ghp_FAKE_TOKEN_FOR_TESTING_00000000000
google_api=FAKE_AIzaSy_GOOGLE_API_KEY_FOR_TESTING
stripe_key=sk_test_FAKE_STRIPE_KEY_FOR_TESTING_ONLY
EOF

    if [ -f "$test_file" ]; then
        test_pass "測試檔案創建成功"
    else
        test_fail "測試檔案創建失敗"
        return
    fi

    # 載入安全檢查模組並測試
    test_start "測試安全模式檢測"
    if source "$SCRIPT_DIR/security_check.sh" 2>/dev/null; then
        # 初始化安全模式
        if init_security_patterns 2>/dev/null; then
            local patterns_found=0
            local detected_patterns=()

            for pattern_name in "${!SECURITY_PATTERNS[@]}"; do
                local pattern="${SECURITY_PATTERNS[$pattern_name]}"
                if grep -qE "$pattern" "$test_file" 2>/dev/null; then
                    ((patterns_found++))
                    local display_name=$(get_pattern_display_name "$pattern_name" 2>/dev/null || echo "$pattern_name")
                    detected_patterns+=("$display_name")
                    test_info "檢測到：$display_name"
                fi
            done

            if [ "$patterns_found" -gt 5 ]; then
                test_pass "成功檢測到 $patterns_found 種安全模式"
            else
                test_warning "只檢測到 $patterns_found 種安全模式（預期 > 5）"
            fi
        else
            test_fail "安全模式初始化失敗"
        fi
    else
        test_fail "無法載入安全檢查模組"
    fi

    # 測試檔案過濾功能
    test_start "測試檔案過濾功能"
    local test_binary="test.jpg"
    touch "$test_binary"

    if should_check_file "$test_file" && ! should_check_file "$test_binary"; then
        test_pass "檔案過濾功能正常"
    else
        test_fail "檔案過濾功能異常"
    fi

    # 清理測試檔案
    rm -f "$test_file" "$test_binary"

    echo ""
}

# 測試錯誤處理
test_error_handling() {
    echo -e "${PURPLE}==================== 錯誤處理測試 ====================${NC}"

    # 測試在非 Git 目錄中運行
    test_start "測試非 Git 目錄錯誤處理"
    local temp_dir=$(mktemp -d)
    if [ -d "$temp_dir" ]; then
        cd "$temp_dir"

        local error_output=$("$SCRIPT_DIR/git_sync.sh" 2>&1)
        if echo "$error_output" | grep -q "不是 Git 倉庫"; then
            test_pass "正確檢測非 Git 目錄"
        else
            test_fail "未正確檢測非 Git 目錄"
        fi

        cd "$SCRIPT_DIR"
        rmdir "$temp_dir"
    else
        test_fail "無法創建臨時目錄"
    fi

    # 測試缺少模組檔案的情況
    test_start "測試缺少模組檔案錯誤處理"
    local backup_dir=$(mktemp -d)

    if [ -d "$backup_dir" ]; then
        # 備份模組檔案
        cp remote_config.sh "$backup_dir/" 2>/dev/null

        # 臨時移除模組檔案
        mv remote_config.sh remote_config.sh.bak 2>/dev/null

        local missing_module_output=$("$SCRIPT_DIR/git_sync.sh" 2>&1)
        if echo "$missing_module_output" | grep -q "找不到模組檔案"; then
            test_pass "正確檢測缺少模組檔案"
        else
            test_fail "未正確檢測缺少模組檔案"
        fi

        # 恢復模組檔案
        mv remote_config.sh.bak remote_config.sh 2>/dev/null

        rm -rf "$backup_dir"
    else
        test_fail "無法創建備份目錄"
    fi

    echo ""
}

# 測試效能
test_performance() {
    echo -e "${PURPLE}==================== 效能測試 ====================${NC}"

    test_start "測試腳本啟動時間"
    local start_time=$(date +%s.%N 2>/dev/null)
    "$SCRIPT_DIR/git_sync.sh" --version >/dev/null 2>&1
    local end_time=$(date +%s.%N 2>/dev/null)

    if [ ! -z "$start_time" ] && [ ! -z "$end_time" ]; then
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "無法計算")

        if echo "$duration" | grep -q "^[0-9]"; then
            if [ "$(echo "$duration < 3" | bc 2>/dev/null)" = "1" ]; then
                test_pass "啟動時間：${duration}秒（良好）"
            else
                test_warning "啟動時間：${duration}秒（較慢）"
            fi
        else
            test_info "啟動時間：無法精確測量"
        fi
    else
        test_info "啟動時間：無法測量（系統不支援）"
    fi

    # 測試記憶體使用
    test_start "測試記憶體使用"
    local memory_info=$(ps -o pid,vsz,rss,comm -p $$ 2>/dev/null | tail -1)
    if [ ! -z "$memory_info" ]; then
        test_pass "記憶體使用情況：$memory_info"
    else
        test_info "無法檢測記憶體使用情況"
    fi

    # 測試檔案大小
    test_start "檢查腳本檔案大小"
    local total_size=0
    local scripts=("git_sync.sh" "remote_config.sh" "security_check.sh")

    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            local size=$(wc -c <"$script" 2>/dev/null)
            total_size=$((total_size + size))
        fi
    done

    if [ "$total_size" -gt 0 ]; then
        local total_kb=$((total_size / 1024))
        if [ "$total_kb" -lt 100 ]; then
            test_pass "總檔案大小：${total_kb}KB（精簡）"
        else
            test_info "總檔案大小：${total_kb}KB"
        fi
    fi

    echo ""
}

# 生成測試報告
generate_report() {
    echo -e "${PURPLE}==================== 測試報告 ====================${NC}"

    echo -e "${BLUE}測試概要：${NC}"
    echo -e "  總測試數：$TOTAL_TESTS"
    echo -e "  通過：${GREEN}$PASSED_TESTS${NC}"
    echo -e "  失敗：${RED}$FAILED_TESTS${NC}"
    echo -e "  警告：${YELLOW}${#WARNINGS[@]}${NC}"

    local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))

    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "  結果：${GREEN}所有測試通過 ✓ (${pass_rate}%)${NC}"
    else
        echo -e "  結果：${RED}有測試失敗 ✗ (${pass_rate}%)${NC}"
    fi

    echo ""
    echo -e "${BLUE}詳細結果：${NC}"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}警告：${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo "  $warning"
        done
    fi

    echo ""
    echo -e "${BLUE}建議：${NC}"

    if [ "$FAILED_TESTS" -gt 0 ]; then
        echo -e "  ${YELLOW}• 請修正失敗的測試項目${NC}"
        echo -e "  ${YELLOW}• 確保所有模組檔案存在且有執行權限${NC}"
        echo -e "  ${YELLOW}• 檢查 Bash 版本是否支援關聯陣列${NC}"
    fi

    # 檢查 'all' 遠端配置
    if git remote | grep -q "^all$"; then
        local all_urls=$(git remote get-url --all --push all 2>/dev/null)
        local unique_urls=$(echo "$all_urls" | sort -u | wc -l)
        if [ "$unique_urls" -eq 1 ]; then
            echo -e "  ${YELLOW}• 'all' 遠端配置可能不正確，所有 URL 相同${NC}"
            echo -e "  ${YELLOW}• 建議執行：git remote remove all 然後重新配置${NC}"
        fi
    fi

    echo -e "  ${GREEN}• 執行 ./git_sync.sh --debug 可查看詳細執行過程${NC}"
    echo -e "  ${GREEN}• 執行 ./git_sync.sh --help 可查看使用說明${NC}"
    echo -e "  ${CYAN}• 如需更多協助，請查看 README.md${NC}"

    # 生成測試報告檔案
    local report_file="test_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "Git 同步工具測試報告"
        echo "生成時間: $(date)"
        echo "========================================"
        echo ""
        echo "測試統計:"
        echo "  總測試數: $TOTAL_TESTS"
        echo "  通過: $PASSED_TESTS"
        echo "  失敗: $FAILED_TESTS"
        echo "  通過率: ${pass_rate}%"
        echo ""
        echo "詳細結果:"
        for result in "${TEST_RESULTS[@]}"; do
            echo "  $result"
        done
        if [ ${#WARNINGS[@]} -gt 0 ]; then
            echo ""
            echo "警告:"
            for warning in "${WARNINGS[@]}"; do
                echo "  $warning"
            done
        fi
    } >"$report_file"

    echo -e "  ${CYAN}• 詳細報告已保存至：$report_file${NC}"

    echo ""
}

# 主函數
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Git 同步工具完整測試 v2.1        ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    test_environment
    test_files
    test_syntax
    test_module_loading
    test_main_script
    test_git_config
    test_security_check
    test_error_handling
    test_performance

    generate_report

    # 返回適當的退出碼
    if [ "$FAILED_TESTS" -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# 顯示使用說明
show_usage() {
    echo -e "${BLUE}Git 同步工具測試腳本使用說明：${NC}"
    echo ""
    echo -e "${YELLOW}用途：${NC}全面測試 git_sync.sh 的所有功能"
    echo ""
    echo -e "${YELLOW}使用方法：${NC}"
    echo "  ./test_git_sync.sh        執行完整測試"
    echo "  ./test_git_sync.sh -h     顯示此說明"
    echo "  ./test_git_sync.sh -v     顯示版本資訊"
    echo "  ./test_git_sync.sh -q     安靜模式（只顯示結果）"
    echo ""
    echo -e "${YELLOW}測試項目：${NC}"
    echo "  • 環境檢查（Bash、Git 版本）"
    echo "  • 檔案存在性和權限"
    echo "  • 語法檢查"
    echo "  • 模組載入測試"
    echo "  • 主腳本功能測試"
    echo "  • Git 配置分析"
    echo "  • 安全檢查功能"
    echo "  • 錯誤處理測試"
    echo "  • 效能測試"
    echo ""
    echo -e "${YELLOW}返回值：${NC}"
    echo "  0 - 所有測試通過"
    echo "  1 - 有測試失敗"
}

# 處理命令列參數
case "$1" in
-h | --help)
    show_usage
    exit 0
    ;;
-v | --version)
    echo "Git 同步工具測試腳本 v2.1"
    echo "支援完整的功能測試和效能分析"
    exit 0
    ;;
-q | --quiet)
    # 安靜模式（可以在這裡修改輸出）
    main
    ;;
*)
    main
    ;;
esac
