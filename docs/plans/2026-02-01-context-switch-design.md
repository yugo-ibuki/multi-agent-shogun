# Shogun Context Switch 設計書

> **Date**: 2026-02-01
> **Status**: Approved

## 概要

複数プロジェクトを shogun で並行管理するための、コンテキスト切り替えコマンド。

## 課題

- shogun は1つだが、複数プロジェクトで使いたい
- dashboard.md や queue/*.yaml などの状態が混ざってしまう
- 並行して複数プロジェクトを動かしたい場合がある

## 解決策

プロジェクトごとの状態を `repositories/<project-name>/` に保存・復元できるコマンドを提供。
worktree と組み合わせて並行開発を可能にする。

## ワークフロー

### 並行開発を始める

```
1. save oauth-client    → 状態を退避
2. reset                → クリーンに
3. worktree new-project → 新しい worktree 作成
4. restore oauth-client → 元の方を復元
→ 両方のプロジェクトを並行して動かせる
```

### プロジェクト完了後、worktree を再利用

```
1. (worktree側で) reset       → 完了したプロジェクトをクリア
2. (worktree側で) restore xxx → 別の保存済みプロジェクトを復元
   または新規プロジェクト開始
```

## コマンド設計

### ファイル名
`shogun_context.sh`

### サブコマンド

| コマンド | 説明 |
|---------|------|
| `save <project-name>` | 現在の状態を `repositories/<project-name>/` に保存 |
| `reset` | shogun をクリーン状態にリセット |
| `restore <project-name>` | 保存した状態を復元 |
| `worktree <path>` | git worktree を新規作成 |
| `list` | 保存済みプロジェクト一覧を表示 |
| `delete <project-name>` | 保存済みプロジェクトを削除 |

### 保存対象ファイル

- `dashboard.md`
- `queue/*.yaml`
- `status/*.yaml`
- `config/projects.yaml`

### ディレクトリ構造

```
multi-agent-shogun/
├── repositories/           # 保存先（新規作成）
│   ├── oauth-client/
│   │   ├── dashboard.md
│   │   ├── queue/
│   │   ├── status/
│   │   └── config/
│   └── another-project/
│       └── ...
├── shogun_context.sh       # 新規コマンド
└── ...
```

## 実装詳細

### save コマンド
1. `repositories/<project-name>/` ディレクトリを作成
2. 対象ファイルをコピー
3. 保存日時をメタデータとして記録

### reset コマンド
1. dashboard.md を初期状態に戻す
2. queue/*.yaml をクリア
3. status/*.yaml をクリア
4. config/projects.yaml をデフォルトに

### restore コマンド
1. `repositories/<project-name>/` の存在確認
2. 対象ファイルを元の場所にコピー（上書き）

### worktree コマンド
1. `git worktree add <path>` を実行
2. 新しい worktree で `./shutsujin_departure.sh` が使えることを確認

## 注意事項

- save 時に同名プロジェクトが存在する場合は上書き確認
- restore 時に現在の状態が保存されていない場合は警告
- worktree 作成時は現在のブランチから分岐
