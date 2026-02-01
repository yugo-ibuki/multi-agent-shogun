#!/bin/bash
# 🏯 Shogun Context Switch - プロジェクト状態の保存・復元・並行開発
#
# 使用方法:
#   ./shogun_context.sh save <project-name>     # 状態を保存
#   ./shogun_context.sh restore <project-name>  # 状態を復元
#   ./shogun_context.sh reset                   # クリーン状態にリセット
#   ./shogun_context.sh worktree <path>         # 新しい worktree を作成

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 定数
REPO_DIR="$SCRIPT_DIR/repositories"

# 保存対象ファイル/ディレクトリ
SAVE_TARGETS=(
    "dashboard.md"
    "config/projects.yaml"
    "status/master_status.yaml"
    "queue/shogun_to_karo.yaml"
    "queue/karo_to_ashigaru.yaml"
    "queue/tasks"
    "queue/reports"
)

# 色付きログ関数
log_info() {
    echo -e "\033[1;33m【報】\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m【成】\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m【誤】\033[0m $1"
}

log_war() {
    echo -e "\033[1;35m【戦】\033[0m $1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# save - 現在の状態を保存
# ═══════════════════════════════════════════════════════════════════════════════
cmd_save() {
    local project_name="$1"

    if [ -z "$project_name" ]; then
        log_error "プロジェクト名を指定してください"
        echo "使用方法: ./shogun_context.sh save <project-name>"
        exit 1
    fi

    local save_dir="$REPO_DIR/$project_name"

    # 既存チェック
    if [ -d "$save_dir" ]; then
        log_info "既存の保存データが見つかりました: $project_name"
        read -p "上書きしますか？ [y/N]: " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            log_info "保存をキャンセルしました"
            exit 0
        fi
        rm -rf "$save_dir"
    fi

    log_war "⚔️ プロジェクト状態を保存中: $project_name"

    # ディレクトリ作成
    mkdir -p "$save_dir/queue/tasks"
    mkdir -p "$save_dir/queue/reports"
    mkdir -p "$save_dir/config"
    mkdir -p "$save_dir/status"

    # ファイルをコピー
    for target in "${SAVE_TARGETS[@]}"; do
        if [ -e "$SCRIPT_DIR/$target" ]; then
            if [ -d "$SCRIPT_DIR/$target" ]; then
                cp -r "$SCRIPT_DIR/$target"/* "$save_dir/$target/" 2>/dev/null || true
            else
                cp "$SCRIPT_DIR/$target" "$save_dir/$target"
            fi
            log_info "  └─ $target"
        fi
    done

    # メタデータを保存
    cat > "$save_dir/.metadata.yaml" << EOF
project_name: $project_name
saved_at: $(date "+%Y-%m-%d %H:%M:%S")
saved_from: $(pwd)
git_branch: $(git branch --show-current 2>/dev/null || echo "unknown")
EOF

    log_success "✅ 保存完了: $save_dir"
}

# ═══════════════════════════════════════════════════════════════════════════════
# restore - 保存した状態を復元
# ═══════════════════════════════════════════════════════════════════════════════
cmd_restore() {
    local project_name="$1"

    if [ -z "$project_name" ]; then
        log_error "プロジェクト名を指定してください"
        echo "使用方法: ./shogun_context.sh restore <project-name>"
        echo ""
        echo "保存済みプロジェクト:"
        cmd_list
        exit 1
    fi

    local save_dir="$REPO_DIR/$project_name"

    if [ ! -d "$save_dir" ]; then
        log_error "保存データが見つかりません: $project_name"
        echo ""
        echo "保存済みプロジェクト:"
        cmd_list
        exit 1
    fi

    log_war "⚔️ プロジェクト状態を復元中: $project_name"

    # ファイルを復元
    for target in "${SAVE_TARGETS[@]}"; do
        if [ -e "$save_dir/$target" ]; then
            if [ -d "$save_dir/$target" ]; then
                # ディレクトリの場合は中身をコピー
                mkdir -p "$SCRIPT_DIR/$target"
                cp -r "$save_dir/$target"/* "$SCRIPT_DIR/$target/" 2>/dev/null || true
            else
                # ファイルの場合はそのままコピー
                mkdir -p "$(dirname "$SCRIPT_DIR/$target")"
                cp "$save_dir/$target" "$SCRIPT_DIR/$target"
            fi
            log_info "  └─ $target"
        fi
    done

    # メタデータを表示
    if [ -f "$save_dir/.metadata.yaml" ]; then
        echo ""
        log_info "復元元情報:"
        cat "$save_dir/.metadata.yaml" | sed 's/^/  /'
    fi

    log_success "✅ 復元完了: $project_name"
}

# ═══════════════════════════════════════════════════════════════════════════════
# reset - クリーン状態にリセット
# ═══════════════════════════════════════════════════════════════════════════════
cmd_reset() {
    log_war "⚔️ shogun をクリーン状態にリセット中..."

    # 現在の状態が保存されているか確認
    read -p "現在の状態を保存してからリセットしますか？ [y/N]: " save_first
    if [ "$save_first" = "y" ] || [ "$save_first" = "Y" ]; then
        read -p "プロジェクト名: " project_name
        if [ -n "$project_name" ]; then
            cmd_save "$project_name"
        fi
    fi

    log_info "🧹 リセット実行中..."

    # dashboard.md を初期化
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
    cat > "$SCRIPT_DIR/dashboard.md" << EOF
# 📊 戦況報告
最終更新: ${TIMESTAMP}

## 🚨 要対応 - 殿のご判断をお待ちしております
なし

## 🔄 進行中 - 只今、戦闘中でござる
なし

## ✅ 本日の戦果
| 時刻 | 戦場 | 任務 | 結果 |
|------|------|------|------|

## 🎯 スキル化候補 - 承認待ち
なし

## 🛠️ 生成されたスキル
なし

## ⏸️ 待機中
なし

## ❓ 伺い事項
なし
EOF
    log_info "  └─ dashboard.md"

    # config/projects.yaml を初期化
    cat > "$SCRIPT_DIR/config/projects.yaml" << EOF
projects: []

current_project: null
EOF
    log_info "  └─ config/projects.yaml"

    # status/master_status.yaml を初期化
    cat > "$SCRIPT_DIR/status/master_status.yaml" << EOF
last_updated: null
current_task: null
task_status: idle
task_description: null
agents:
  shogun:
    status: idle
    last_action: null
  karo:
    status: idle
    current_subtasks: 0
    last_action: null
  ashigaru1:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
  ashigaru2:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
  ashigaru3:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
  ashigaru4:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
  ashigaru5:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
  ashigaru6:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
  ashigaru7:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
  ashigaru8:
    status: idle
    current_task: null
    progress: 0
    last_completed: null
EOF
    log_info "  └─ status/master_status.yaml"

    # queue/shogun_to_karo.yaml を初期化
    cat > "$SCRIPT_DIR/queue/shogun_to_karo.yaml" << 'EOF'
queue: []
EOF
    log_info "  └─ queue/shogun_to_karo.yaml"

    # queue/karo_to_ashigaru.yaml を初期化
    cat > "$SCRIPT_DIR/queue/karo_to_ashigaru.yaml" << 'EOF'
assignments:
  ashigaru1:
    task_id: null
    description: null
    target_path: null
    status: idle
  ashigaru2:
    task_id: null
    description: null
    target_path: null
    status: idle
  ashigaru3:
    task_id: null
    description: null
    target_path: null
    status: idle
  ashigaru4:
    task_id: null
    description: null
    target_path: null
    status: idle
EOF
    log_info "  └─ queue/karo_to_ashigaru.yaml"

    # queue/tasks/*.yaml を初期化
    for i in {1..8}; do
        cat > "$SCRIPT_DIR/queue/tasks/ashigaru${i}.yaml" << EOF
worker_id: ashigaru${i}
task_id: null
description: null
target_path: null
status: idle
EOF
    done
    log_info "  └─ queue/tasks/ashigaru*.yaml"

    # queue/reports/*.yaml を初期化
    for i in {1..8}; do
        cat > "$SCRIPT_DIR/queue/reports/ashigaru${i}_report.yaml" << EOF
worker_id: ashigaru${i}
task_id: null
timestamp: ""
status: idle
result: null
EOF
    done
    log_info "  └─ queue/reports/ashigaru*_report.yaml"

    log_success "✅ リセット完了"
}

# ═══════════════════════════════════════════════════════════════════════════════
# worktree - 新しい worktree を作成
# ═══════════════════════════════════════════════════════════════════════════════
cmd_worktree() {
    local worktree_path="$1"

    if [ -z "$worktree_path" ]; then
        log_error "worktree のパスを指定してください"
        echo "使用方法: ./shogun_context.sh worktree <path>"
        echo ""
        echo "例: ./shogun_context.sh worktree ../multi-agent-shogun-projectB"
        exit 1
    fi

    # 絶対パスに変換
    if [[ "$worktree_path" != /* ]]; then
        worktree_path="$(pwd)/$worktree_path"
    fi

    log_war "⚔️ 新しい worktree を作成中: $worktree_path"

    # 現在のブランチ名を取得
    local current_branch=$(git branch --show-current)
    local new_branch="worktree-$(basename "$worktree_path")"

    # worktree を作成
    log_info "ブランチ '$new_branch' を作成して worktree を追加..."
    git worktree add -b "$new_branch" "$worktree_path" "$current_branch"

    log_success "✅ worktree 作成完了: $worktree_path"
    echo ""
    log_info "次のステップ:"
    echo "  1. cd $worktree_path"
    echo "  2. ./shutsujin_departure.sh  # 新しい shogun を起動"
    echo ""
    log_info "worktree 一覧:"
    git worktree list
}

# ═══════════════════════════════════════════════════════════════════════════════
# list - 保存済みプロジェクト一覧
# ═══════════════════════════════════════════════════════════════════════════════
cmd_list() {
    if [ ! -d "$REPO_DIR" ] || [ -z "$(ls -A "$REPO_DIR" 2>/dev/null)" ]; then
        echo "  (保存済みプロジェクトなし)"
        return
    fi

    echo ""
    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  📁 保存済みプロジェクト                                  │"
    echo "  └──────────────────────────────────────────────────────────┘"

    for dir in "$REPO_DIR"/*/; do
        if [ -d "$dir" ]; then
            local name=$(basename "$dir")
            local saved_at=""

            if [ -f "$dir/.metadata.yaml" ]; then
                saved_at=$(grep "saved_at:" "$dir/.metadata.yaml" | cut -d' ' -f2-)
            fi

            echo "  • $name"
            if [ -n "$saved_at" ]; then
                echo "    └─ 保存日時: $saved_at"
            fi
        fi
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# help - ヘルプ表示
# ═══════════════════════════════════════════════════════════════════════════════
cmd_help() {
    echo ""
    echo "🏯 Shogun Context Switch - プロジェクト状態の保存・復元・並行開発"
    echo ""
    echo "使用方法: ./shogun_context.sh <command> [options]"
    echo ""
    echo "コマンド:"
    echo "  save <project-name>     現在の状態を保存"
    echo "  restore <project-name>  保存した状態を復元"
    echo "  reset                   クリーン状態にリセット"
    echo "  worktree <path>         新しい worktree を作成"
    echo ""
    echo "ワークフロー例（並行開発）:"
    echo "  1. ./shogun_context.sh save projectA        # 現在の状態を保存"
    echo "  2. ./shogun_context.sh reset                # リセット"
    echo "  3. ./shogun_context.sh worktree ../shogun2  # 新しい worktree 作成"
    echo "  4. ./shogun_context.sh restore projectA     # 元の環境を復元"
    echo "  → 2つの shogun を並行して動かせる！"
    echo ""
    echo "ワークフロー例（worktree 再利用）:"
    echo "  1. (worktree側で) ./shogun_context.sh reset     # 完了プロジェクトをクリア"
    echo "  2. (worktree側で) ./shogun_context.sh restore X # 別プロジェクトを復元"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# メイン処理
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    # repositories ディレクトリがなければ作成
    mkdir -p "$REPO_DIR"

    local command="${1:-help}"
    shift || true

    case "$command" in
        save)
            cmd_save "$@"
            ;;
        restore)
            cmd_restore "$@"
            ;;
        reset)
            cmd_reset "$@"
            ;;
        worktree)
            cmd_worktree "$@"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            log_error "不明なコマンド: $command"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
