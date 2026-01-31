#!/bin/bash
# ============================================================
# first_setup.sh - multi-agent-shogun 初回セットアップスクリプト
# macOS 専用環境構築ツール
# ============================================================
# 前提条件:
#   - macOS
#   - tmux, Node.js, Claude Code CLI がインストール済み
#
# 実行方法:
#   chmod +x first_setup.sh
#   ./first_setup.sh
# ============================================================

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# アイコン付きログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"
}

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 結果追跡用変数
RESULTS=()
HAS_ERROR=false

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  🏯 multi-agent-shogun インストーラー                         ║"
echo "  ║     Initial Setup Script for macOS                           ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  このスクリプトは初回セットアップ用です。"
echo "  依存関係の確認とディレクトリ構造の作成を行います。"
echo ""

# ============================================================
# STEP 1: macOS チェック
# ============================================================
log_step "STEP 1: システム環境チェック"

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_VERSION=$(sw_vers -productVersion)
    log_success "macOS $OS_VERSION を検出しました"
    RESULTS+=("システム環境: macOS $OS_VERSION")
else
    log_error "このスクリプトは macOS 専用です"
    echo ""
    echo "  検出されたOS: $OSTYPE"
    echo "  macOS 以外の環境では動作しません。"
    exit 1
fi

# ============================================================
# STEP 2: 必須ツールの確認
# ============================================================
log_step "STEP 2: 必須ツールの確認"

MISSING_TOOLS=()

# tmux チェック
if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V | awk '{print $2}')
    log_success "tmux: v$TMUX_VERSION"
    RESULTS+=("tmux: OK (v$TMUX_VERSION)")
else
    log_error "tmux がインストールされていません"
    MISSING_TOOLS+=("tmux")
fi

# Node.js チェック
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | tr -d 'v')

    if [ "$NODE_MAJOR" -lt 18 ]; then
        log_warn "Node.js: $NODE_VERSION (18以上を推奨)"
        RESULTS+=("Node.js: OK ($NODE_VERSION) - アップグレード推奨")
    else
        log_success "Node.js: $NODE_VERSION"
        RESULTS+=("Node.js: OK ($NODE_VERSION)")
    fi
else
    log_error "Node.js がインストールされていません"
    MISSING_TOOLS+=("node")
fi

# npm チェック
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    log_success "npm: v$NPM_VERSION"
else
    if command -v node &> /dev/null; then
        log_warn "npm が見つかりません"
        MISSING_TOOLS+=("npm")
    fi
fi

# Claude Code CLI チェック
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    log_success "Claude Code CLI: $CLAUDE_VERSION"
    RESULTS+=("Claude Code CLI: OK")
else
    log_error "Claude Code CLI がインストールされていません"
    MISSING_TOOLS+=("claude")
fi

# 未インストールツールがある場合はエラー終了
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo ""
    log_error "以下のツールがインストールされていません:"
    echo ""
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "  - $tool"
    done
    echo ""
    echo "  インストール方法:"
    echo "    tmux:           brew install tmux"
    echo "    Node.js:        brew install node  (または nvm を使用)"
    echo "    Claude Code:    npm install -g @anthropic-ai/claude-code"
    echo ""
    exit 1
fi

# ============================================================
# STEP 3: tmux マウススクロール設定
# ============================================================
log_step "STEP 3: tmux マウススクロール設定"

TMUX_CONF="$HOME/.tmux.conf"

# マウス設定の確認・追加
if [ -f "$TMUX_CONF" ]; then
    if grep -q "set -g mouse on" "$TMUX_CONF"; then
        log_info "マウススクロール設定は既に有効です"
    else
        log_info "マウススクロール設定を追加中..."
        echo "" >> "$TMUX_CONF"
        echo "# multi-agent-shogun: マウススクロール有効化" >> "$TMUX_CONF"
        echo "set -g mouse on" >> "$TMUX_CONF"
        log_success "マウススクロール設定を追加しました"
    fi
else
    log_info "~/.tmux.conf を作成中..."
    cat > "$TMUX_CONF" << 'EOF'
# multi-agent-shogun: マウススクロール有効化
set -g mouse on
EOF
    log_success "~/.tmux.conf を作成しました（マウススクロール有効）"
fi

RESULTS+=("tmux設定: OK")

# ============================================================
# STEP 4: ディレクトリ構造作成
# ============================================================
log_step "STEP 4: ディレクトリ構造作成"

# 必要なディレクトリ一覧
DIRECTORIES=(
    "queue/tasks"
    "queue/reports"
    "config"
    "status"
    "instructions"
    "logs"
    "demo_output"
    "skills"
)

CREATED_COUNT=0
EXISTED_COUNT=0

for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
        mkdir -p "$SCRIPT_DIR/$dir"
        log_info "作成: $dir/"
        ((CREATED_COUNT++))
    else
        ((EXISTED_COUNT++))
    fi
done

if [ $CREATED_COUNT -gt 0 ]; then
    log_success "$CREATED_COUNT 個のディレクトリを作成しました"
fi
if [ $EXISTED_COUNT -gt 0 ]; then
    log_info "$EXISTED_COUNT 個のディレクトリは既に存在します"
fi

RESULTS+=("ディレクトリ構造: OK (作成:$CREATED_COUNT, 既存:$EXISTED_COUNT)")

# ============================================================
# STEP 5: 設定ファイル初期化
# ============================================================
log_step "STEP 5: 設定ファイル確認"

# config/settings.yaml
if [ ! -f "$SCRIPT_DIR/config/settings.yaml" ]; then
    log_info "config/settings.yaml を作成中..."
    cat > "$SCRIPT_DIR/config/settings.yaml" << 'EOF'
# multi-agent-shogun 設定ファイル

# 言語設定
# ja: 日本語（戦国風日本語のみ、併記なし）
# en: 英語（戦国風日本語 + 英訳併記）
# その他の言語コード（es, zh, ko, fr, de 等）も対応
language: ja

# スキル設定
skill:
  # スキル保存先（生成されたスキルはここに保存）
  save_path: "~/.claude/skills/shogun-generated/"

  # ローカルスキル保存先（このプロジェクト専用）
  local_path: "~/multi-agent-shogun/skills/"

# ログ設定
logging:
  level: info  # debug | info | warn | error
  path: "~/multi-agent-shogun/logs/"
EOF
    log_success "settings.yaml を作成しました"
else
    log_info "config/settings.yaml は既に存在します"
fi

# config/projects.yaml
if [ ! -f "$SCRIPT_DIR/config/projects.yaml" ]; then
    log_info "config/projects.yaml を作成中..."
    cat > "$SCRIPT_DIR/config/projects.yaml" << 'EOF'
projects:
  - id: sample_project
    name: "Sample Project"
    path: "/path/to/your/project"
    priority: high
    status: active

current_project: sample_project
EOF
    log_success "projects.yaml を作成しました"
else
    log_info "config/projects.yaml は既に存在します"
fi

RESULTS+=("設定ファイル: OK")

# ============================================================
# STEP 6: 足軽用タスク・レポートファイル初期化
# ============================================================
log_step "STEP 6: キューファイル初期化"

# 足軽用タスクファイル作成
for i in {1..8}; do
    TASK_FILE="$SCRIPT_DIR/queue/tasks/ashigaru${i}.yaml"
    if [ ! -f "$TASK_FILE" ]; then
        cat > "$TASK_FILE" << EOF
# 足軽${i}専用タスクファイル
task:
  task_id: null
  parent_cmd: null
  description: null
  target_path: null
  status: idle
  timestamp: ""
EOF
    fi
done
log_info "足軽タスクファイル (1-8) を確認/作成しました"

# 足軽用レポートファイル作成
for i in {1..8}; do
    REPORT_FILE="$SCRIPT_DIR/queue/reports/ashigaru${i}_report.yaml"
    if [ ! -f "$REPORT_FILE" ]; then
        cat > "$REPORT_FILE" << EOF
worker_id: ashigaru${i}
task_id: null
timestamp: ""
status: idle
result: null
EOF
    fi
done
log_info "足軽レポートファイル (1-8) を確認/作成しました"

RESULTS+=("キューファイル: OK")

# ============================================================
# STEP 7: スクリプト実行権限付与
# ============================================================
log_step "STEP 7: 実行権限設定"

SCRIPTS=(
    "shutsujin_departure.sh"
    "first_setup.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        chmod +x "$SCRIPT_DIR/$script"
        log_info "$script に実行権限を付与しました"
    fi
done

RESULTS+=("実行権限: OK")

# ============================================================
# 結果サマリー
# ============================================================
echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  📋 セットアップ結果サマリー                                  ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""

for result in "${RESULTS[@]}"; do
    if [[ $result == *"未インストール"* ]] || [[ $result == *"失敗"* ]]; then
        echo -e "  ${RED}✗${NC} $result"
    elif [[ $result == *"アップグレード"* ]] || [[ $result == *"スキップ"* ]]; then
        echo -e "  ${YELLOW}!${NC} $result"
    else
        echo -e "  ${GREEN}✓${NC} $result"
    fi
done

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  ✅ セットアップ完了！準備万端でござる！                      ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"

echo ""
echo "  ┌──────────────────────────────────────────────────────────────┐"
echo "  │  📜 次のステップ                                             │"
echo "  └──────────────────────────────────────────────────────────────┘"
echo ""
echo "  出陣（全エージェント起動）:"
echo "     ./shutsujin_departure.sh"
echo ""
echo "  オプション:"
echo "     ./shutsujin_departure.sh -s   # セットアップのみ（Claude手動起動）"
echo ""
echo "  詳細は README.md を参照してください。"
echo ""
echo "  ════════════════════════════════════════════════════════════════"
echo "   天下布武！ (Tenka Fubu!)"
echo "  ════════════════════════════════════════════════════════════════"
echo ""
