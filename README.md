# Git 同步工具（模組化版本）

一個功能強大的 Git 倉庫同步工具，支援 GitLab 和 GitHub 雙平台同步，並具備完整的安全檢查功能。

## 功能特色

- **雙平台同步**：自動檢測和配置 GitLab 與 GitHub 遠端
- **安全檢查**：推送前自動檢測機密資訊，防止敏感資料洩露
- **模組化設計**：程式碼結構清晰，易於維護和擴展
- **互動式操作**：提供友善的使用者介面和多種處理選項
- **智慧配置**：自動設置合併遠端，支援一鍵推送到多個倉庫

## 檔案結構

```
.
├── git_sync.sh          # 主腳本
├── remote_config.sh     # 遠端配置模組
├── security_check.sh    # 安全檢查模組
└── README.md           # 使用說明
```

## 安裝與設置

### 1. 下載檔案

將所有檔案下載到同一個目錄中：

- `git_sync.sh`
- `remote_config.sh`
- `security_check.sh`

### 2. 設置執行權限

```bash
chmod +x git_sync.sh
chmod +x remote_config.sh
chmod +x security_check.sh
```

### 3. 移動到 PATH（可選）

將腳本移動到系統 PATH 中，以便在任何地方使用：

```bash
# 移動到 /usr/local/bin（需要管理員權限）
sudo cp git_sync.sh /usr/local/bin/
sudo cp remote_config.sh /usr/local/bin/
sudo cp security_check.sh /usr/local/bin/

# 或者移動到個人 bin 目錄
mkdir -p ~/bin
cp *.sh ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 使用方法

### 基本使用

在 Git 倉庫目錄中執行：

```bash
./git_sync.sh
```

### 命令列選項

```bash
# 顯示說明
./git_sync.sh --help

# 顯示版本資訊
./git_sync.sh --version
```

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
