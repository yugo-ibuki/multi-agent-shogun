#!/bin/bash
# ============================================================
# first_setup.sh - multi-agent-shogun 初回セットアップスクリプト
# ============================================================
# 実行方法:
#   ./first_setup.sh
# ============================================================

set -e

# 色定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_step() { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  🏯 multi-agent-shogun セットアップ                          ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================
# STEP 1: ディレクトリ構造作成
# ============================================================
log_step "STEP 1: ディレクトリ構造作成"

DIRECTORIES=("queue/tasks" "queue/reports" "config" "status" "instructions" "logs" "demo_output" "skills")
CREATED=0

for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
        mkdir -p "$SCRIPT_DIR/$dir"
        log_info "作成: $dir/"
        ((CREATED++))
    fi
done

[ $CREATED -gt 0 ] && log_success "$CREATED 個のディレクトリを作成" || log_info "全て既存"

# ============================================================
# STEP 2: 設定ファイル初期化
# ============================================================
log_step "STEP 2: 設定ファイル初期化"

if [ ! -f "$SCRIPT_DIR/config/settings.yaml" ]; then
    cat > "$SCRIPT_DIR/config/settings.yaml" << 'EOF'
# multi-agent-shogun 設定ファイル
language: ja
skill:
  save_path: "~/.claude/skills/shogun-generated/"
  local_path: "~/multi-agent-shogun/skills/"
logging:
  level: info
  path: "~/multi-agent-shogun/logs/"
EOF
    log_success "settings.yaml 作成"
else
    log_info "settings.yaml 既存"
fi

if [ ! -f "$SCRIPT_DIR/config/projects.yaml" ]; then
    cat > "$SCRIPT_DIR/config/projects.yaml" << 'EOF'
projects:
  - id: sample_project
    name: "Sample Project"
    path: "/path/to/your/project"
    priority: high
    status: active
current_project: sample_project
EOF
    log_success "projects.yaml 作成"
else
    log_info "projects.yaml 既存"
fi

# ============================================================
# STEP 3: キューファイル初期化
# ============================================================
log_step "STEP 3: キューファイル初期化"

for i in {1..4}; do
    TASK_FILE="$SCRIPT_DIR/queue/tasks/ashigaru${i}.yaml"
    [ ! -f "$TASK_FILE" ] && cat > "$TASK_FILE" << EOF
task:
  task_id: null
  parent_cmd: null
  description: null
  target_path: null
  status: idle
  timestamp: ""
EOF
done
log_info "足軽タスクファイル (1-4) 確認完了"

for i in {1..4}; do
    REPORT_FILE="$SCRIPT_DIR/queue/reports/ashigaru${i}_report.yaml"
    [ ! -f "$REPORT_FILE" ] && cat > "$REPORT_FILE" << EOF
worker_id: ashigaru${i}
task_id: null
timestamp: ""
status: idle
result: null
EOF
done
log_info "足軽レポートファイル (1-4) 確認完了"

# ============================================================
# STEP 4: 実行権限設定
# ============================================================
log_step "STEP 4: 実行権限設定"

for script in "shutsujin_departure.sh" "first_setup.sh"; do
    [ -f "$SCRIPT_DIR/$script" ] && chmod +x "$SCRIPT_DIR/$script"
done
log_success "実行権限付与完了"

# ============================================================
# 完了
# ============================================================
echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  ✅ セットアップ完了！                                        ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  次のステップ: ./shutsujin_departure.sh"
echo ""
