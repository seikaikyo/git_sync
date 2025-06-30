#!/bin/bash

# 遠端配置模組
# 負責 GitLab 和 GitHub 遠端的檢測、配置和管理

# 全域變數
DETECTED_GITLAB_REMOTE=""
DETECTED_GITHUB_REMOTE=""

# 配置所有遠端倉庫的主函數
configure_remotes() {
    echo -e "${YELLOW}檢查 Git 遠端...${NC}"
    git remote -v
    echo ""
    
    # 配置 GitLab 遠端
    configure_gitlab_remote
    
    # 配置 GitHub 遠端
    configure_github_remote
    
    echo ""
}

# 配置 GitLab 遠端
configure_gitlab_remote() {
    echo -e "${BLUE}檢查 GitLab 遠端配置...${NC}"
    
    # 首先查找明確命名為 gitlab 的遠端
    if git remote -v | grep -q "gitlab"; then
        DETECTED_GITLAB_REMOTE=$(git remote -v | grep "gitlab" | grep "(push)" | head -n1 | awk '{print $1}')
        echo -e "${GREEN}✓ 找到 GitLab 遠端：${DETECTED_GITLAB_REMOTE}${NC}"
    else
        # 查找指向 GitLab 的 URL
        local gitlab_remote=""
        while read -r remote_name remote_url _; do
            if echo "$remote_url" | grep -q "gitlab"; then
                gitlab_remote="$remote_name"
                break
            fi
        done < <(git remote -v | grep "(push)")
        
        if [ ! -z "$gitlab_remote" ]; then
            DETECTED_GITLAB_REMOTE="$gitlab_remote"
            echo -e "${GREEN}✓ 找到指向 GitLab 的遠端：${DETECTED_GITLAB_REMOTE}${NC}"
        else
            echo -e "${RED}✗ 未找到 GitLab 遠端${NC}"
            prompt_add_gitlab_remote
        fi
    fi
}

# 提示新增 GitLab 遠端
prompt_add_gitlab_remote() {
    echo -e "${YELLOW}是否要添加 GitLab 遠端？(y/n)${NC}"
    read add_gitlab
    
    if [ "$add_gitlab" = "y" ] || [ "$add_gitlab" = "Y" ]; then
        echo -e "${YELLOW}請輸入您的 GitLab 倉庫 URL：${NC}"
        read gitlab_url
        
        # 驗證 URL 格式
        if validate_git_url "$gitlab_url"; then
            git remote add gitlab "$gitlab_url"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ GitLab 遠端添加成功${NC}"
                DETECTED_GITLAB_REMOTE="gitlab"
            else
                echo -e "${RED}✗ 添加 GitLab 遠端失敗${NC}"
            fi
        else
            echo -e "${RED}✗ 無效的 Git URL 格式${NC}"
        fi
    fi
}

# 配置 GitHub 遠端
configure_github_remote() {
    echo -e "${BLUE}檢查 GitHub 遠端配置...${NC}"
    
    # 首先查找明確命名為 github 的遠端
    if git remote -v | grep -q "github" | head -1; then
        local github_remote_name=$(git remote -v | grep "github" | grep "(push)" | head -n1 | awk '{print $1}')
        local github_remote_url=$(git remote -v | grep "github" | grep "(push)" | head -n1 | awk '{print $2}')
        
        # 確認 URL 確實指向 GitHub
        if echo "$github_remote_url" | grep -q "github.com"; then
            DETECTED_GITHUB_REMOTE="$github_remote_name"
            echo -e "${GREEN}✓ 找到 GitHub 遠端：${DETECTED_GITHUB_REMOTE}${NC}"
        else
            # 遠端名稱包含 github 但 URL 不是指向 GitHub
            echo -e "${YELLOW}警告：遠端 '$github_remote_name' 命名包含 'github' 但 URL 不指向 GitHub${NC}"
            find_github_by_url
        fi
    else
        find_github_by_url
    fi
}

# 根據 URL 查找 GitHub 遠端
find_github_by_url() {
    local github_remote=""
    while read -r remote_name remote_url _; do
        if echo "$remote_url" | grep -q "github.com"; then
            github_remote="$remote_name"
            break
        fi
    done < <(git remote -v | grep "(push)")
    
    if [ ! -z "$github_remote" ]; then
        DETECTED_GITHUB_REMOTE="$github_remote"
        echo -e "${GREEN}✓ 找到指向 GitHub 的遠端：${DETECTED_GITHUB_REMOTE}${NC}"
    else
        echo -e "${RED}✗ 未找到 GitHub 遠端${NC}"
        prompt_add_github_remote
    fi
}

# 提示新增 GitHub 遠端
prompt_add_github_remote() {
    echo -e "${YELLOW}是否要添加 GitHub 遠端？(y/n)${NC}"
    read add_github
    
    if [ "$add_github" = "y" ] || [ "$add_github" = "Y" ]; then
        echo -e "${YELLOW}請輸入您的 GitHub 倉庫 URL：${NC}"
        read github_url
        
        # 驗證 URL 格式
        if validate_git_url "$github_url"; then
            git remote add github "$github_url"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ GitHub 遠端添加成功${NC}"
                DETECTED_GITHUB_REMOTE="github"
            else
                echo -e "${RED}✗ 添加 GitHub 遠端失敗${NC}"
            fi
        else
            echo -e "${RED}✗ 無效的 Git URL 格式${NC}"
        fi
    fi
}

# 設置合併遠端（用於同時推送到兩個倉庫）
setup_all_remote() {
    local gitlab_remote="$1"
    local github_remote="$2"
    
    if [ -z "$gitlab_remote" ] || [ -z "$github_remote" ]; then
        echo -e "${YELLOW}無法設置合併遠端：缺少必要的遠端配置${NC}"
        return 1
    fi
    
    # 檢查是否已經設置 'all' 遠端
    if ! git remote -v | grep -q "all"; then
        echo -e "${YELLOW}是否要設置一個 'all' 遠端以同時推送到兩個倉庫？(y/n)${NC}"
        read setup_all
        
        if [ "$setup_all" = "y" ] || [ "$setup_all" = "Y" ]; then
            create_all_remote "$gitlab_remote" "$github_remote"
        fi
    else
        echo -e "${GREEN}✓ 'all' 遠端已配置${NC}"
        display_all_remote_info
    fi
}

# 創建合併遠端
create_all_remote() {
    local gitlab_remote="$1"
    local github_remote="$2"
    
    local gitlab_url=$(git remote get-url --push "$gitlab_remote")
    local github_url=$(git remote get-url --push "$github_remote")
    
    if [ -z "$gitlab_url" ] || [ -z "$github_url" ]; then
        echo -e "${RED}✗ 無法獲取遠端 URL${NC}"
        return 1
    fi
    
    # 添加 all 遠端
    git remote add all "$gitlab_url"
    git remote set-url --add --push all "$gitlab_url"
    git remote set-url --add --push all "$github_url"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 成功設置 'all' 遠端${NC}"
        echo -e "${YELLOW}現在您可以使用以下命令推送到兩個倉庫：${GREEN}git push all${NC}"
        display_all_remote_info
    else
        echo -e "${RED}✗ 設置 'all' 遠端失敗${NC}"
        return 1
    fi
}

# 顯示合併遠端資訊
display_all_remote_info() {
    echo -e "${BLUE}'all' 遠端配置：${NC}"
    git remote get-url --all --push all | while read url; do
        echo -e "${YELLOW}  → $url${NC}"
    done
}

# 驗證 Git URL 格式
validate_git_url() {
    local url="$1"
    
    # 檢查基本的 Git URL 格式
    if echo "$url" | grep -qE '^(https?://|git@|ssh://git@)'; then
        return 0
    else
        return 1
    fi
}

# 獲取 GitLab 遠端名稱
get_gitlab_remote() {
    echo "$DETECTED_GITLAB_REMOTE"
}

# 獲取 GitHub 遠端名稱
get_github_remote() {
    echo "$DETECTED_GITHUB_REMOTE"
}

# 檢查遠端是否存在
remote_exists() {
    local remote_name="$1"
    git remote | grep -q "^$remote_name$"
}

# 獲取遠端 URL
get_remote_url() {
    local remote_name="$1"
    git remote get-url "$remote_name" 2>/dev/null
}

# 列出所有遠端
list_all_remotes() {
    echo -e "${BLUE}所有已配置的遠端：${NC}"
    git remote -v | while read line; do
        echo -e "${YELLOW}  $line${NC}"
    done
}

# 移除遠端
remove_remote() {
    local remote_name="$1"
    
    if remote_exists "$remote_name"; then
        echo -e "${YELLOW}確定要移除遠端 '$remote_name' 嗎？(y/n)${NC}"
        read confirm
        
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            git remote remove "$remote_name"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ 成功移除遠端 '$remote_name'${NC}"
            else
                echo -e "${RED}✗ 移除遠端 '$remote_name' 失敗${NC}"
            fi
        fi
    else
        echo -e "${RED}遠端 '$remote_name' 不存在${NC}"
    fi
}

# 重新命名遠端
rename_remote() {
    local old_name="$1"
    local new_name="$2"
    
    if remote_exists "$old_name"; then
        git remote rename "$old_name" "$new_name"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 成功將遠端 '$old_name' 重新命名為 '$new_name'${NC}"
        else
            echo -e "${RED}✗ 重新命名遠端失敗${NC}"
        fi
    else
        echo -e "${RED}遠端 '$old_name' 不存在${NC}"
    fi
}

# 測試遠端連線
test_remote_connection() {
    local remote_name="$1"
    
    if remote_exists "$remote_name"; then
        echo -e "${YELLOW}測試遠端 '$remote_name' 的連線...${NC}"
        git ls-remote --heads "$remote_name" >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ 遠端 '$remote_name' 連線正常${NC}"
            return 0
        else
            echo -e "${RED}✗ 遠端 '$remote_name' 連線失敗${NC}"
            return 1
        fi
    else
        echo -e "${RED}遠端 '$remote_name' 不存在${NC}"
        return 1
    fi
}