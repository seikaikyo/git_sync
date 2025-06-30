# Git 同步工具（模組化版本）

一個功能強大的 Git 倉庫同步工具，支援 GitLab 和 GitHub 雙平台同步，並具備完整的安全檢查功能。

## 功能特色

- **雙平台同步**：自動檢測和配置 GitLab 與 GitHub 遠端
- **安全檢查**：推送前自動檢測機密資訊，防止敏感資料洩露
- **模組化設計**：程式碼結構清晰，易於維護和擴展
- **互動式操作**：提供友善的使用者介面和多種處理選項
- **智慧配置**：自動設置合併遠端，支援一鍵推送到多個倉庫
- **調試模式**：提供詳細的執行日誌協助故障排除

## 檔案結構

```
.
├── git_sync.sh          # 主腳本
├── remote_config.sh     # 遠端配置模組
├── security_check.sh    # 安全檢查模組
├── test_git_sync.sh     # 測試腳本（可選）
└── README.md           # 使用說明
```

## 快速開始

### 1. 下載並設置權限

```bash
# 下載檔案後設置執行權限
chmod +x git_sync.sh remote_config.sh security_check.sh
```

### 2. 基本使用

```bash
# 在 Git 倉庫目錄中執行
./git_sync.sh

# 查看版本資訊
./git_sync.sh --version

# 啟用調試模式
./git_sync.sh --debug
```

### 3. 首次使用流程

1. 腳本會自動檢測現有的 Git 遠端
2. 如果只有 GitHub 遠端，會提示是否添加 GitLab 遠端
3. 可選擇設置 'all' 遠端以同時推送到兩個平台
4. 執行安全檢查掃描機密資訊
5. 確認後推送到配置的遠端

## 安裝與設置

### 系統需求

- Bash 4.0 或更高版本
- Git 2.0 或更高版本
- 支援 macOS、Linux 和 Windows（Git Bash）

### 安裝到系統 PATH（可選）

```bash
# 移動到系統目錄（需要管理員權限）
sudo cp *.sh /usr/local/bin/

# 或者移動到個人 bin 目錄
mkdir -p ~/bin
cp *.sh ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 使用方法

### 命令列選項

```bash
./git_sync.sh [選項]

選項：
  -h, --help     顯示使用說明
  -v, --version  顯示版本資訊
  -d, --debug    啟用調試模式（顯示詳細執行過程）
```

### 使用範例

```bash
# 基本同步（互動式）
./git_sync.sh

# 調試模式（查看詳細執行過程）
./git_sync.sh --debug

# 快速查看版本
./git_sync.sh --version
```

## 功能說明

### 1. 遠端配置管理

工具會自動：

- **檢測現有遠端**：自動識別 GitLab 和 GitHub 遠端
- **智慧假設**：如果只有 origin，會根據 URL 判斷平台
- **互動式配置**：提示用戶添加缺少的遠端
- **合併遠端設置**：創建 'all' 遠端以支援同時推送
- **URL 驗證**：確保遠端 URL 格式正確

### 2. 安全檢查功能

在推送前自動檢測以下類型的機密資訊：

#### 憑證類型

| 類型       | 檢測模式                              | 說明           |
| ---------- | ------------------------------------- | -------------- |
| 密碼       | `password=`, `pwd=`                   | 各種密碼配置   |
| API 金鑰   | `api_key=`, `secret_key=`             | API 存取憑證   |
| JWT 權杖   | `jwt=`, `token=`, `bearer=`           | 身份驗證權杖   |
| 資料庫連線 | `database_url=`, `connection_string=` | 資料庫連線字串 |

#### 平台特定權杖

- **AWS**：`AKIA...` 開頭的存取金鑰
- **GitHub**：`ghp_...` 開頭的個人存取權杖
- **Slack**：`xox...` 開頭的機器人權杖

#### 個人資訊

- **電子郵件**：標準電子郵件格式
- **手機號碼**：台灣手機號碼格式 (`+886` 或 `09...`)
- **信用卡號**：16 位數信用卡號碼格式

#### 金鑰檔案

- **SSH 私鑰**：`-----BEGIN PRIVATE KEY-----` 開頭
- **其他私鑰**：RSA、DSA、EC 格式私鑰

### 3. 安全問題處理選項

當發現機密資訊時，提供以下處理方式：

1. **查看詳細內容**：顯示具體匹配的內容和行號
2. **加入 .gitignore**：自動將問題檔案加入忽略清單並從暫存區移除
3. **繼續推送**：在充分了解風險後強制推送（強烈不建議）
4. **取消推送**：安全地終止操作

## 工作流程

```mermaid
graph TD
    A[開始] --> B[檢查 Git 倉庫]
    B --> C[載入模組]
    C --> D[配置遠端倉庫]
    D --> E[執行安全檢查]
    E --> F{發現機密資訊?}
    F -->|是| G[顯示安全問題]
    F -->|否| H[執行推送]
    G --> I[處理安全問題]
    I --> J{繼續推送?}
    J -->|是| H
    J -->|否| K[終止]
    H --> L[完成]
```

## 進階使用

### 獨立使用模組

#### 遠端配置模組

```bash
source remote_config.sh

# 配置所有遠端
configure_remotes

# 獲取遠端名稱
gitlab_remote=$(get_gitlab_remote)
github_remote=$(get_github_remote)

# 測試遠端連線
test_remote_connection "origin"
```

#### 安全檢查模組

```bash
source security_check.sh

# 執行完整安全檢查
perform_security_check

# 處理發現的安全問題
handle_security_issues
```

### 自訂安全檢查模式

修改 `security_check.sh` 中的 `init_security_patterns()` 函數：

```bash
# 添加自訂檢查模式
SECURITY_PATTERNS["custom_pattern"]="your_regex_pattern_here"

# 同時更新顯示名稱函數
get_pattern_display_name() {
    case "$1" in
        "custom_pattern") echo "自訂模式" ;;
        # ... 其他模式
    esac
}
```

## 環境變數最佳實踐

### 1. 建立環境變數檔案

```bash
# .env.example（加入版本控制）
API_KEY=your_api_key_here
DATABASE_URL=your_database_url_here
JWT_SECRET=your_jwt_secret_here
SMTP_PASSWORD=your_smtp_password_here

# .env（加入 .gitignore）
API_KEY=actual_secret_api_key_value
DATABASE_URL=postgresql://user:pass@localhost/mydb
JWT_SECRET=actual_jwt_secret_token
SMTP_PASSWORD=actual_email_password
```

### 2. 更新 .gitignore

```gitignore
# 環境變數檔案
.env
.env.local
.env.production
.env.staging

# 配置檔案
config.json
secrets.yml
credentials.txt

# 金鑰檔案
*.pem
*.key
*.p12
```

### 3. 程式碼中使用環境變數

```javascript
// Node.js
const config = {
    apiKey: process.env.API_KEY || 'default_development_key',
    dbUrl: process.env.DATABASE_URL || 'sqlite://memory'
};

// Python
import os
API_KEY = os.getenv('API_KEY', 'default_development_key')
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///:memory:')
```

## 故障排除

### 常見問題

#### 1. 模組載入失敗

```
錯誤：載入 remote_config.sh 失敗
```

**解決方法**：

- 確保所有 `.sh` 檔案在同一目錄
- 檢查檔案權限：`chmod +x *.sh`
- 使用調試模式：`./git_sync.sh --debug`

#### 2. 關聯陣列語法錯誤

```
syntax error: invalid arithmetic operator
```

**解決方法**：

- 確保使用 Bash 4.0+ 版本：`bash --version`
- 在 Windows 上使用 Git Bash 而非 PowerShell

#### 3. Git 遠端配置問題

```
無法獲取遠端 URL
```

**解決方法**：

- 檢查 Git 遠端：`git remote -v`
- 確保在 Git 倉庫目錄中執行
- 檢查網路連線和權限

#### 4. 安全檢查誤報

```
發現機密資訊：電子郵件
```

**解決方法**：

- 檢查是否為測試用假資料
- 考慮修改正則表達式模式
- 使用選項 2 將檔案加入 .gitignore

### 調試技巧

```bash
# 1. 啟用腳本調試模式
./git_sync.sh --debug

# 2. 使用 Bash 除錯模式
bash -x ./git_sync.sh

# 3. 檢查語法
bash -n ./git_sync.sh

# 4. 執行測試腳本
./test_git_sync.sh

# 5. 逐步檢查模組
source remote_config.sh && echo "遠端模組載入成功"
source security_check.sh && echo "安全模組載入成功"
```

## 效能優化

- **檔案檢查限制**：預設只檢查前 10 個追蹤的檔案
- **排除二進位檔案**：自動跳過圖片、文件等二進位檔案
- **正則表達式優化**：使用高效的正則表達式模式

## 貢獻指南

歡迎提交 Issue 和 Pull Request！

### 開發建議

1. **保持模組化**：新功能應該放在適當的模組中
2. **遵循命名規範**：使用描述性的函數和變數名稱
3. **添加註釋**：為複雜邏輯添加中文註釋
4. **測試變更**：確保修改不影響現有功能
5. **更新文件**：同步更新 README.md

### 提交規範

```bash
git commit -m "feat: 新增 XXX 功能"
git commit -m "fix: 修正 XXX 問題"
git commit -m "docs: 更新使用文件"
```

## 安全注意事項

⚠️ **重要提醒**：

- **永不提交機密資訊**到公開倉庫
- **定期輪換金鑰**：API 金鑰、權杖應定期更新
- **使用環境變數**：敏感配置應存放在環境變數中
- **檢查 .gitignore**：確保機密檔案被正確忽略
- **審查提交內容**：推送前仔細檢查變更內容

## 授權

本專案採用 MIT 授權條款。詳見 [LICENSE](LICENSE) 檔案。

## 版本歷史

- **v2.1**：改進安全檢查算法，修正關聯陣列語法問題
- **v2.0**：模組化重構，新增更多安全檢查模式
- **v1.0**：初始版本，基本的同步功能

## 相關資源

- [Git 官方文件](https://git-scm.com/docs)
- [GitHub 使用指南](https://docs.github.com/)
- [GitLab 使用指南](https://docs.gitlab.com/)
- [Bash 腳本指南](https://www.gnu.org/software/bash/manual/)

---

如有問題或建議，歡迎開啟 [Issue](../../issues) 討論！

## 功能說明

### 1. 遠端配置管理

工具會自動：

- 檢測現有的 GitLab 和 GitHub 遠端
- 提示新增缺少的遠端配置
- 設置 'all' 遠端以支援同時推送到兩個平台
- 驗證遠端 URL 格式

### 2. 安全檢查功能

在推送前自動檢測以下類型的機密資訊：

#### 一般憑證

- 密碼 (password, passwd, pwd)
- API 金鑰 (api_key, access_key, secret_key)
- JWT 權杖 (jwt, token, bearer)
- 資料庫連線字串 (database_url, connection_string)

#### 平台特定權杖

- AWS 金鑰 (AKIA...)
- GitHub 權杖 (ghp\_...)
- Slack 權杖 (xox...)
- Google API 金鑰 (AIza...)
- Facebook 權杖 (EAA...)
- Twitter 權杖
- Docker Hub 權杖 (dckr*pat*...)

#### 個人資訊

- 電子郵件地址
- 手機號碼（台灣格式）
- 信用卡號

#### 金鑰檔案

- SSH 私鑰
- RSA/DSA/EC 私鑰

### 3. 安全問題處理選項

當發現機密資訊時，提供以下處理方式：

1. **查看詳細內容**：顯示具體的匹配內容和行號
2. **加入 .gitignore**：自動將問題檔案加入忽略清單
3. **創建環境變數範本**：生成 .env.example 檔案
4. **繼續推送**：在確認風險後強制推送（不建議）
5. **取消推送**：安全地終止操作

## 工作流程

```
開始
  ↓
檢查 Git 倉庫
  ↓
配置遠端倉庫
  ↓
執行安全檢查
  ↓
發現問題？ ── 否 ──→ 執行推送
  ↓是
處理安全問題
  ↓
重新檢查或終止
```

## 進階使用

### 獨立使用模組

#### 遠端配置模組

```bash
source remote_config.sh

# 配置所有遠端
configure_remotes

# 獲取 GitLab 遠端名稱
gitlab_remote=$(get_gitlab_remote)

# 測試遠端連線
test_remote_connection "origin"
```

#### 安全檢查模組

```bash
source security_check.sh

# 執行完整安全檢查
perform_security_check

# 檢查特定檔案
check_file_security "config.js"

# 掃描整個專案
scan_entire_project
```

### 自訂安全檢查模式

修改 `security_check.sh` 中的 `init_security_patterns()` 函數以新增自訂的檢查模式：

```bash
SECURITY_PATTERNS["自訂模式"]="your_regex_pattern_here"
```

## 環境變數最佳實踐

### 1. 使用 .env 檔案

```bash
# .env.example（加入版本控制）
API_KEY=your_api_key_here
DATABASE_URL=your_database_url_here
SECRET_TOKEN=your_secret_token_here

# .env（不要加入版本控制）
API_KEY=actual_api_key_value
DATABASE_URL=postgresql://user:pass@localhost/db
SECRET_TOKEN=actual_secret_token
```

### 2. 更新 .gitignore

```
# 環境變數檔案
.env
.env.local
.env.production

# 配置檔案
config.json
secrets.yml
```

### 3. 程式碼中使用環境變數

```javascript
// Node.js 範例
const apiKey = process.env.API_KEY || 'default_value';

// Python 範例
import os
api_key = os.getenv('API_KEY', 'default_value')
```

## 故障排除

### 常見問題

1. **模組檔案找不到**

   ```
   錯誤：缺少必要的模組檔案
   ```

   解決方法：確保所有檔案都在同一目錄中

2. **權限錯誤**

   ```
   Permission denied
   ```

   解決方法：使用 `chmod +x *.sh` 設置執行權限

3. **Git 遠端配置錯誤**
   ```
   無法獲取遠端 URL
   ```
   解決方法：檢查 Git 遠端配置是否正確

### 除錯模式

在腳本開頭加入除錯模式：

```bash
set -x  # 啟用除錯模式
set -e  # 遇到錯誤時立即退出
```

## 貢獻指南

歡迎提交 Issue 和 Pull Request 來改善這個工具。

### 開發建議

1. 保持模組化設計原則
2. 新增功能時更新相應的文件
3. 確保向後相容性
4. 遵循現有的程式碼風格

## 安全注意事項

- 永遠不要在公開倉庫中提交機密資訊
- 定期檢查和更新 .gitignore 檔案
- 使用環境變數管理敏感配置
- 定期輪換 API 金鑰和權杖

## 授權

本專案採用 MIT 授權條款。

## 版本歷史

- **v2.0**：模組化重構，新增更多安全檢查模式
- **v1.0**：初始版本，基本的同步功能
