# チーム開発セーフティ戦略 🛡️

## 🎯 課題：開発ツールの多様性

### 現実的な開発環境
- **Xcode**: iOSメイン開発者
- **VS Code**: フルスタック開発者  
- **IntelliJ**: モバイル・バックエンド開発者
- **Cursor**: AI重視開発者
- **ブラウザベースAI**: ChatGPT/Claude直接使用者

### ❌ Cursor Rules for AI の限界
- Cursorユーザーのみに適用
- 他のエディタでは無効
- AI非使用者には影響なし

## 🔐 レイヤード・セーフティ戦略

### Layer 1: Git レベル保護（最強・全員適用）

#### **Pre-commit フック**
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 重要ファイル変更チェック..."

# 禁止パターンチェック
if git diff --cached --name-only | grep -E "(build\.sh|Podfile)"; then
    if git diff --cached build.sh | grep -E "(FREERDP_VERSION|OPENSSL_VERSION)" && ! git log -1 --pretty=%B | grep -E "APPROVED.*VERSION"; then
        echo "❌ エラー: ライブラリバージョン変更は事前承認必須"
        echo "💡 対処: コミットメッセージに 'APPROVED-VERSION-CHANGE' を含めてください"
        exit 1
    fi
fi

echo "✅ チェック完了"
```

#### **GitHub Actions CI/CD**
```yaml
# .github/workflows/safety-check.yml
name: Safety Check
on: [push, pull_request]
jobs:
  safety-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check Library Versions
        run: |
          if git diff HEAD~1..HEAD build.sh | grep -E "(FREERDP_VERSION|OPENSSL_VERSION)"; then
            if ! git log -1 --pretty=%B | grep "APPROVED-VERSION"; then
              echo "❌ 未承認のライブラリバージョン変更検出"
              exit 1
            fi
          fi
```

### Layer 2: プロジェクトレベル保護

#### **Makefile による統一チェック**
```makefile
# Makefile
.PHONY: safety-check

safety-check:
	@echo "🔍 プロジェクトセーフティチェック..."
	@python3 scripts/safety_checker.py
	@echo "✅ セーフティチェック完了"

build: safety-check
	./build.sh deps
```

#### **設定チェッカースクリプト**
```python
# scripts/safety_checker.py
import re
import sys

def check_library_versions():
    """build.shのライブラリバージョンをチェック"""
    expected_versions = {
        'FREERDP_VERSION': '3.15.0',
        'OPENSSL_VERSION': '3.4.0'
    }
    
    with open('build.sh', 'r') as f:
        content = f.read()
    
    for lib, version in expected_versions.items():
        pattern = f'{lib}="([^"]+)"'
        match = re.search(pattern, content)
        if not match or match.group(1) != version:
            print(f"❌ {lib} バージョン不一致: 期待={version}")
            return False
    
    print("✅ ライブラリバージョン確認")
    return True

if __name__ == "__main__":
    if not check_library_versions():
        sys.exit(1)
```

### Layer 3: エディタ固有の保護

#### **VS Code Settings**
```json
// .vscode/settings.json
{
    "files.readonlyInclude": {
        "build.sh": true,
        "Podfile": true
    },
    "github.copilot.enable": {
        "*": true,
        "yaml": false,
        "plaintext": false
    }
}
```

#### **Xcode User Scripts**
```bash
# Xcode Build Phases → New Run Script Phase
if [ "${CONFIGURATION}" = "Release" ]; then
    echo "🔍 リリースビルド前チェック..."
    python3 "${SRCROOT}/scripts/safety_checker.py"
fi
```

### Layer 4: ドキュメント＆コミュニケーション

#### **README 強化**
- 🚨 **変更禁止事項**を最上位に明記
- **チーム全員**が読む場所に警告

#### **Slack/Teams 統合**
```python
# GitHub Webhook → Slack
def alert_critical_changes(commit_data):
    if 'build.sh' in commit_data.modified_files:
        send_slack_alert(
            "🚨 重要: build.sh が変更されました！レビュー必須",
            commit_data
        )
```

## 🎯 実装優先度

### 🔥 最優先（即座実装）
1. **Pre-commit フック** - 全開発者に適用
2. **GitHub Actions チェック** - Pull Request時に自動実行
3. **README 警告強化** - 視認性最大化

### ⚡ 高優先（1週間以内）
4. **Python セーフティチェッカー** - 複合チェック機能
5. **Makefile 統合** - ビルド前自動チェック

### 📋 中優先（必要に応じて）
6. **エディタ固有設定** - 各ツール用カスタマイズ
7. **Slack/Teams 統合** - チーム通知自動化

## 🎪 現実的な運用戦略

### チーム導入アプローチ
1. **段階的導入**
   - まずGitフックから開始
   - 段階的にチェック強化

2. **チーム教育**
   - 制約の理由説明
   - 回避方法の明示

3. **フィードバックループ**
   - 運用上の問題収集
   - ルール調整

### 柔軟性の確保
```bash
# 緊急時の承認フロー
git commit -m "EMERGENCY-OVERRIDE: OpenSSL緊急パッチ適用

承認者: @team-lead
理由: CVE-2024-XXXX対応
影響: 最小限"
```

## 📊 効果測定

### KPI
- **未承認変更の検出率**: 100%目標
- **False Positive率**: 5%未満
- **チーム生産性影響**: 軽微

### モニタリング
- GitHub Actions 実行ログ
- Pre-commit フック実行統計
- チームフィードバック収集

---

**結論**: Cursor Rules for AI は有用だが、チーム全体の保護には **Gitレベル + CI/CD での強制チェック** が必須 