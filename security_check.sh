
#!/bin/bash



# 安全檢查模組

# 負責檢測機密資訊並提供相應的處理措施



# 全域變數

declare -A FOUND_SECURITY_ISSUES

declare -A SECURITY_PATTERNS

SECURITY_CHECK_PASSED=true



# 初始化安全檢查模式

init_security_patterns() {

    # 定義機密資訊的正則表達式模式（使用英文鍵值避免語法錯誤）

    SECURITY_PATTERNS["password"]="(password|passwd|pwd)\s*[=:]\s*[\"']?[^\s\"']{3,}[\"']?"

    SECURITY_PATTERNS["api_key"]="(api[_-]?key|apikey|access[_-]?key|secret[_-]?key)\s*[=:]\s*[\"']?[a-zA-Z0-9_-]{10,}[\"']?"

    SECURITY_PATTERNS["jwt_token"]="(jwt|token|bearer)\s*[=:]\s*[\"']?[a-zA-Z0-9_.-]{20,}[\"']?"

    SECURITY_PATTERNS["database_url"]="(database[_-]?url|db[_-]?url|connection[_-]?string)\s*[=:]\s*[\"']?[^\s\"']{10,}[\"']?"

    SECURITY_PATTERNS["email"]="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

    SECURITY_PATTERNS["phone"]="(\+?886|0)[0-9]{8,9}"

    SECURITY_PATTERNS["credit_card"]="[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}"

    SECURITY_PATTERNS["private_key"]="-----BEGIN (RSA |DSA |EC )?PRIVATE KEY-----"

    SECURITY_PATTERNS["aws_key"]="AKIA[0-9A-Z]{16}"

    SECURITY_PATTERNS["github_token"]="ghp_[a-zA-Z0-9]{36}"

    SECURITY_PATTERNS["slack_token"]="xox[bpsr]-[a-zA-Z0-9-]+"

}



# 獲取模式的顯示名稱（中文）

get_pattern_display_name() {

    local pattern_key="$1"

    case "$pattern_key" in

        "password") echo "密碼" ;;

        "api_key") echo "API金鑰" ;;

        "jwt_token") echo "JWT權杖" ;;

        "database_url") echo "資料庫連線" ;;

        "email") echo "電子郵件" ;;

        "phone") echo "手機號碼" ;;

        "credit_card") echo "信用卡號" ;;

        "private_key") echo "私鑰" ;;

        "aws_key") echo "AWS金鑰" ;;

        "github_token") echo "GitHub權杖" ;;

        "slack_token") echo "Slack權杖" ;;

        *) echo "$pattern_key" ;;

    esac

}



# 執行安全檢查的主函數

perform_security_check() {

    echo -e "${BLUE}正在檢查機密資訊...${NC}"

    

    # 初始化檢查模式

    init_security_patterns

    

    # 重置全域變數

    unset FOUND_SECURITY_ISSUES

    declare -A FOUND_SECURITY_ISSUES

    SECURITY_CHECK_PASSED=true

    

    # 獲取要檢查的檔案

    local files_to_check=$(get_files_to_check)

    

    if [ -z "$files_to_check" ]; then

        echo -e "${YELLOW}沒有檔案需要檢查${NC}"

        return 0

    fi

    

    # 執行檢查

    scan_files_for_secrets "$files_to_check"

    

    # 回報結果

    if [ "$SECURITY_CHECK_PASSED" = true ]; then

        echo -e "${GREEN}✓ 未發現機密資訊${NC}"

        return 0

    else

        display_security_issues

        return 1

    fi

}



# 獲取需要檢查的檔案清單

get_files_to_check() {

    local staged_files=$(git diff --cached --name-only 2>/dev/null)

    local modified_files=$(git diff --name-only 2>/dev/null)

    local all_files="$staged_files $modified_files"

    

    # 如果沒有檔案變更，檢查所有追蹤的檔案的前 10 個

    if [ -z "$all_files" ]; then

        all_files=$(git ls-files | head -10)

    fi

    

    # 過濾掉不需要檢查的檔案

    local filtered_files=""

    for file in $all_files; do

        if should_check_file "$file"; then

            filtered_files="$filtered_files $file"

        fi

    done

    

    echo "$filtered_files"

}



# 判斷是否應該檢查該檔案

should_check_file() {

    local file="$1"

    

    # 檢查檔案是否存在

    if [ ! -f "$file" ]; then

        return 1

    fi

    

    # 排除常見的二進位檔案和不需要檢查的檔案

    local excluded_patterns="\.(jpg|jpeg|png|gif|bmp|ico|pdf|doc|docx|xls|xlsx|ppt|pptx|zip|tar|gz|7z|rar|exe|dll|so|dylib|bin|class|jar|war|ear)$"

    

    if echo "$file" | grep -E "$excluded_patterns" > /dev/null; then

        return 1

    fi

    

    return 0

}



# 掃描檔案中的機密資訊

scan_files_for_secrets() {

    local files="$1"

    

    for file in $files; do

        echo -e "${YELLOW}檢查檔案：$file${NC}"

        

        # 檢查每個模式

        for pattern_name in "${!SECURITY_PATTERNS[@]}"; do

            local pattern="${SECURITY_PATTERNS[$pattern_name]}"

            local matches=$(grep -iEn "$pattern" "$file" 2>/dev/null)

            

            if [ ! -z "$matches" ]; then

                SECURITY_CHECK_PASSED=false

                

                # 獲取顯示名稱

                local display_name=$(get_pattern_display_name "$pattern_name")

                

                # 記錄發現的問題（正確處理關聯陣列鍵值）

                if [ -z "${FOUND_SECURITY_ISSUES["$file"]:-}" ]; then

                    FOUND_SECURITY_ISSUES["$file"]="$display_name"

                else

                    FOUND_SECURITY_ISSUES["$file"]="${FOUND_SECURITY_ISSUES["$file"]}, $display_name"

                fi

                

                echo -e "${RED}  ✗ 發現 $display_name${NC}"

            fi

        done

        

        if [ -z "${FOUND_SECURITY_ISSUES["$file"]:-}" ]; then

            echo -e "${GREEN}  ✓ 安全${NC}"

        fi

    done

}



# 顯示安全問題

display_security_issues() {

    echo -e "${RED}警告：發現可能的機密資訊！${NC}"

    echo ""

    

    for file in "${!FOUND_SECURITY_ISSUES[@]}"; do

        echo -e "${YELLOW}檔案：${NC}$file"

        echo -e "${RED}發現的敏感資訊類型：${NC}${FOUND_SECURITY_ISSUES["$file"]}"

        echo ""

    done

}



# 處理安全問題的主函數

handle_security_issues() {

    echo -e "${YELLOW}請選擇處理方式：${NC}"

    echo "1) 查看詳細內容並手動處理"

    echo "2) 將包含機密資訊的檔案加入 .gitignore"

    echo "3) 繼續推送（不建議）"

    echo "4) 取消推送"

    

    read -p "請輸入選項 (1-4): " choice

    

    case $choice in

        1)

            show_detailed_security_issues

            return 1

            ;;

        2)

            add_to_gitignore

            return 1

            ;;

        3)

            confirm_risky_push

            return $?

            ;;

        4)

            echo -e "${YELLOW}推送已取消。${NC}"

            return 1

            ;;

        *)

            echo -e "${RED}無效的選項，推送已取消。${NC}"

            return 1

            ;;

    esac

}



# 顯示詳細的安全問題

show_detailed_security_issues() {

    echo -e "${BLUE}顯示包含機密資訊的詳細內容：${NC}"

    echo ""

    

    for file in "${!FOUND_SECURITY_ISSUES[@]}"; do

        echo -e "${YELLOW}檔案：${NC}$file"

        echo -e "${PURPLE}===========================================${NC}"

        

        for pattern_name in "${!SECURITY_PATTERNS[@]}"; do

            local pattern="${SECURITY_PATTERNS[$pattern_name]}"

            local matches=$(grep -iEn --color=always "$pattern" "$file" 2>/dev/null)

            

            if [ ! -z "$matches" ]; then

                local display_name=$(get_pattern_display_name "$pattern_name")

                echo -e "${RED}$display_name 模式匹配：${NC}"

                echo "$matches"

                echo ""

            fi

        done

        

        echo -e "${PURPLE}===========================================${NC}"

        echo ""

    done

    

    echo -e "${YELLOW}請手動處理後重新執行腳本。${NC}"

}



# 將檔案加入 .gitignore

add_to_gitignore() {

    echo -e "${BLUE}將檔案加入 .gitignore...${NC}"

    

    local added_files=0

    for file in "${!FOUND_SECURITY_ISSUES[@]}"; do

        if ! grep -Fxq "$file" .gitignore 2>/dev/null; then

            echo "$file" >> .gitignore

            echo -e "${GREEN}已將 $file 加入 .gitignore${NC}"

            ((added_files++))

        else

            echo -e "${YELLOW}$file 已在 .gitignore 中${NC}"

        fi

    done

    

    if [ $added_files -gt 0 ]; then

        # 移除已加入 .gitignore 的檔案

        for file in "${!FOUND_SECURITY_ISSUES[@]}"; do

            git rm --cached "$file" 2>/dev/null && echo -e "${YELLOW}已從暫存區移除 $file${NC}"

        done

        

        echo -e "${GREEN}處理完成，請提交 .gitignore 的變更。${NC}"

        echo -e "${YELLOW}建議執行：git add .gitignore && git commit -m \"更新 .gitignore\"${NC}"

    fi

}



# 確認風險推送

confirm_risky_push() {

    echo -e "${RED}警告：您選擇繼續推送，這可能會洩露機密資訊！${NC}"

    read -p "您確定要繼續嗎？(yes/no): " confirm

    

    if [ "$confirm" = "yes" ]; then

        return 0

    else

        return 1

    fi

}

