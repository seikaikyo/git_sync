# Git 同步工具（v2.1 格式化優化版本）

一個功能強大的 Git 倉庫同步工具，支援 GitLab 和 GitHub 雙平台同步，具備完整的安全檢查功能和環境變數管理。

## 🌟 功能特色

- **🔄 雙平台同步**：自動檢測和配置 GitLab 與 GitHub 遠端
- **🔒 安全檢查**：推送前自動檢測 20+ 種機密資訊模式
- **📝 環境變數管理**：自動生成 .env.example 範本
- **🏗️ 模組化設計**：程式碼結構清晰，易於維護和擴展
- **💬 互動式操作**：提供友善的使用者介面和多種處理選項
- **🤖 智慧配置**：自動設置合併遠端，支援一鍵推送到多個倉庫
- **🐛 調試模式**：提供詳細的執行日誌協助故障排除
- **⚡ 效能優化**：快速啟動，精簡檔案大小

## 📂 檔案結構

```
git-sync-tool/
├── git_sync.sh          # 主腳本 (v2.1)
├── remote_config.sh     # 遠端配置模組 (v2.1)
├── security_check.sh    # 安全檢查模組 (v2.1)
├── test_git_sync.sh     # 測試腳本 (v2.1)
└── README.md           # 使用說明
```

## 🚀 快速開始

### 1. 下載並設置權限

```bash
# 下載檔案後設置執行權限
chmod +x git_sync.sh remote_config.sh security_check.sh test_git_sync.sh

# 驗證安裝
./test_git_sync.sh
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

1. **環境檢查**：腳本自動檢測 Git 倉庫和必要工具
2. **遠端配置**：自動識別現有遠端，提示添加缺少的配置
3. **安全檢查**：掃描 20+ 種機密資訊模式
4. **處理選項**：提供 6 種安全問題處理方式
5. **同步推送**：推送到配置的一個或多個遠端

## ⚙️ 安裝與設置

### 系統需求

- **Bash 4.0+**：支援關聯陣列功能
- **Git 2.0+**：基本 Git 操作支援
- **作業系統**：macOS、Linux、Windows (Git Bash)

### 全域安裝（可選）

```bash
# 安裝到系統目錄（需要管理員權限）
sudo cp *.sh /usr/local/bin/

# 或安裝到個人目錄
mkdir -p ~/bin
cp *.sh ~/bin/
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 🔒 安全檢查功能

### 支援的機密資訊類型

#### 🔑 基本認證資訊

| 類型       | 檢測模式                    | 說明           |
| ---------- | --------------------------- | -------------- |
| 密碼       | `password=`, `pwd=`         | 各種密碼配置   |
| API 金鑰   | `api_key=`, `secret_key=`   | API 存取憑證   |
| JWT 權杖   | `jwt=`, `token=`, `bearer=` | 身份驗證權杖   |
| 資料庫連線 | `database_url=`             | 資料庫連線字串 |

#### 🏢 平台特定權杖

- **AWS**：存取金鑰 (`AKIA...`) 和秘密金鑰
- **GitHub**：個人存取權杖 (`ghp_...`、`gh[pousr]_...`)
- **Google**：API 金鑰 (`AIza...`)
- **Slack**：機器人權杖 (`xox...`)
- **Facebook**：存取權杖 (`EAA...`)
- **Twitter**：API 權杖和秘密
- **Docker**：存取權杖 (`dckr_pat_...`)
- **Stripe**：秘密金鑰 (`sk_live_...`)
- **PayPal**：API 憑證

#### 👤 個人資訊

- **電子郵件**：標準格式檢測
- **手機號碼**：台灣格式 (`+886`、`09...`)
- **信用卡號**：16 位數格式

#### 🔐 金鑰檔案

- **SSH 私鑰**：各種格式 (RSA、DSA、EC)
- **SSH 公鑰**：`ssh-rsa`、`ssh-ed25519` 等

### 安全問題處理選項

當發現機密資訊時，提供 6 種處理方式：

1. **📋 查看詳細內容**：顯示具體匹配內容和行號
2. **📝 加入 .gitignore**：自動將問題檔案加入忽略清單
3. **⚙️ 創建環境變數範本**：生成 .env.example 檔案
4. **🔍 掃描整個專案**：進階全專案安全檢查
5. **⚠️ 繼續推送**：在確認風險後強制推送（不建議）
6. **❌ 取消推送**：安全地終止操作

## 🌍 環境變數最佳實踐

### 自動範本生成

```bash
# 腳本會自動生成 .env.example
API_KEY=your_api_key_here
DATABASE_URL=your_database_url_here
JWT_SECRET=your_jwt_secret_here

# 同時更新 .gitignore
.env
.env.local
.env.production
!.env.example
```

### 程式碼中使用環境變數

```javascript
// Node.js
const config = {
    apiKey: process.env.API_KEY || 'default_dev_key',
    dbUrl: process.env.DATABASE_URL || 'sqlite://memory'
};

// Python
import os
API_KEY = os.getenv('API_KEY', 'default_dev_key')
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///:memory:')
```

## 🔧 進階使用

### 獨立使用模組

#### 遠端配置模組

```bash
source remote_config.sh

# 配置所有遠端
configure_remotes

# 修復 GitLab URL 重定向
fix_gitlab_redirect

# 測試所有遠端連線
test_all_remotes
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

# 生成安全報告
generate_security_report
```

### 自訂安全檢查模式

```bash
# 在 security_check.sh 的 init_security_patterns() 中添加
SECURITY_PATTERNS["custom_api"]="custom_api_[a-zA-Z0-9]{32}"

# 更新顯示名稱
get_pattern_display_name() {
    case "$1" in
        "custom_api") echo "自訂API金鑰" ;;
        # ... 其他模式
    esac
}
```

## 🧪 測試與驗證

### 運行完整測試

```bash
# 執行全面測試
./test_git_sync.sh

# 安靜模式
./test_git_sync.sh --quiet

# 查看測試報告
cat test_report_*.txt
```

### 測試項目包括

- ✅ **環境檢查**：Bash、Git 版本驗證
- ✅ **檔案完整性**：語法檢查、權限驗證
- ✅ **模組載入**：函數可用性測試
- ✅ **功能測試**：參數處理、錯誤處理
- ✅ **配置分析**：Git 遠端配置檢查
- ✅ **安全檢查**：模式檢測功能驗證
- ✅ **效能測試**：啟動時間、記憶體使用

## 🐛 故障排除

### 常見問題與解決方案

#### 1. 模組載入失敗

```bash
錯誤：載入 remote_config.sh 失敗
```

**解決方法**：

```bash
# 檢查檔案權限
chmod +x *.sh

# 確認檔案完整性
./test_git_sync.sh

# 使用調試模式
./git_sync.sh --debug
```

#### 2. Bash 版本過舊

```bash
syntax error: invalid arithmetic operator
```

**解決方法**：

```bash
# 檢查 Bash 版本
bash --version

# 升級 Bash (macOS)
brew install bash

# 在 Windows 使用 Git Bash
```

#### 3. GitLab URL 重定向警告

```bash
warning: redirecting to https://gitlab.example.com/repo.git/
```

**解決方法**：

```bash
# 自動修復
source remote_config.sh
fix_gitlab_redirect

# 手動修復
git remote set-url gitlab https://gitlab.example.com/repo.git
```

#### 4. 安全檢查誤報

```bash
發現機密資訊：電子郵件
```

**解決方法**：

- 檢查是否為測試資料
- 將測試檔案加入 .gitignore
- 使用環境變數替換硬編碼值

### 調試技巧

```bash
# 1. 啟用詳細調試
./git_sync.sh --debug

# 2. 使用 Bash 除錯
bash -x ./git_sync.sh

# 3. 檢查語法
bash -n ./git_sync.sh

# 4. 逐步測試模組
source remote_config.sh && echo "遠端模組 OK"
source security_check.sh && echo "安全模組 OK"

# 5. 生成測試報告
./test_git_sync.sh > test_results.txt 2>&1
```

## 📊 效能指標

- **🚀 啟動時間**：< 2 秒（在現代系統上）
- **💾 記憶體使用**：< 10MB
- **📁 檔案大小**：< 100KB（所有模組）
- **🔍 檢查速度**：10 個檔案 < 1 秒

## 🔄 版本歷史

- **v2.1**：格式化優化、新增環境變數管理、URL 自動修正
- **v2.0**：模組化重構、擴展安全檢查模式
- **v1.0**：初始版本、基本同步功能

## 🤝 貢獻指南

歡迎提交 Issue 和 Pull Request！

### 開發建議

1. **保持模組化**：新功能放在適當模組中
2. **遵循規範**：使用描述性函數和變數名稱
3. **添加測試**：確保新功能有對應測試
4. **更新文件**：同步更新 README.md
5. **測試兼容性**：確保 Bash 4.0+ 兼容

### 提交規範

```bash
git commit -m "feat: 新增 XXX 功能"
git commit -m "fix: 修正 XXX 問題"
git commit -m "docs: 更新使用文件"
git commit -m "refactor: 重構 XXX 模組"
git commit -m "test: 新增 XXX 測試"
```

## ⚠️ 安全注意事項

> **重要提醒**

- 🚫 **永不提交機密資訊**到公開倉庫
- 🔄 **定期輪換金鑰**：API 金鑰、權杖應定期更新
- 📝 **使用環境變數**：敏感配置存放在 .env 中
- 🔍 **檢查 .gitignore**：確保機密檔案被正確忽略
- 👀 **審查提交內容**：推送前仔細檢查變更
- 🧪 **測試安全功能**：定期執行 `./test_git_sync.sh`

## 📞 支援與協助

- **📋 問題回報**：[開啟 Issue](../../issues)
- **💡 功能建議**：[開啟 Discussion](../../discussions)
- **📖 詳細文件**：查看各模組內的註釋
- **🧪 執行測試**：`./test_git_sync.sh --help`

## 📜 授權

本專案採用 MIT 授權條款。

## 🔗 相關資源

- [Git 官方文件](https://git-scm.com/docs)
- [GitHub 使用指南](https://docs.github.com/)
- [GitLab 使用指南](https://docs.gitlab.com/)
- [Bash 腳本指南](https://www.gnu.org/software/bash/manual/)
- [環境變數最佳實踐](https://12factor.net/config)

---

**🎉 感謝使用 Git 同步工具！如有問題或建議，歡迎開啟 [Issue](../../issues) 討論！**
