# dotfiles

macOS 向けの個人用 dotfiles です。

## 構成

| ディレクトリ/ファイル | 説明 |
|---|---|
| `zsh/` | zsh 設定（`.zshrc` / `.zprofile`、個人設定は `~/.zshrc.local` に分離） |
| `nvim/` | Neovim 設定（lazy.nvim によるプラグイン管理） |
| `tmux.conf` | tmux 設定（Tokyo Night テーマ、vim 風キーバインド） |
| `ghostty/` | Ghostty ターミナル設定 |
| `setup.sh` | シンボリックリンク作成スクリプト |

## セットアップ

```bash
git clone https://github.com/ShinyaAzuma/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x setup.sh
./setup.sh
```

`setup.sh` により以下のシンボリックリンクが作成されます：

- `~/dotfiles/zsh/zshrc` → `~/.zshrc`
- `~/dotfiles/zsh/zprofile` → `~/.zprofile`
- `~/dotfiles/nvim` → `~/.config/nvim`
- `~/dotfiles/tmux.conf` → `~/.tmux.conf`
- `~/dotfiles/ghostty` → `~/.config/ghostty`

## 主な特徴

### zsh

`zsh/zshrc` と `zsh/zprofile` をリポジトリで管理しています。

本リポジトリは公開のため、**氏名・メールアドレス・ GitHub アカウント名は `~/.zshrc.local` に分離**し、リポジトリには含めていません。`setup.sh` が未作成時のみ `zsh/zshrc.local.example` をコピーするので、自分の値に書き換えてください。

| 変数 | 用途 |
|---|---|
| `GIT_WORK_NAME` / `GIT_WORK_EMAIL` | `gitMain` が設定する作業用アカウント |
| `GIT_PRIV_NAME` / `GIT_PRIV_EMAIL` | `gitPri` が設定する個人アカウント |
| `GH_WORK_USER` | `ghpr` / `ghprw` が集計対象にする GitHub アカウント |

既存の `~/.zshrc` / `~/.zprofile` が実体ファイルの場合、`setup.sh` が `*.bak.<日時>` として退避してからリンクします。

### Neovim
- lazy.nvim によるプラグイン管理
- LSP / Treesitter / fzf / oil.nvim など

### tmux
- プレフィックスキー: `Ctrl+t`
- vim 風ペイン移動 (`h/j/k/l`)
- Lazygit ポップアップ (`prefix + g`)
- Claude Code ポップアップ (`prefix + a`)
- プロジェクトランチャー (`prefix + o`) — sesh + zoxide + fzf で最近/よく開くプロジェクトを曖昧検索して起動・復帰
- セッション永続化 — tmux-resurrect / tmux-continuum で再起動後も前回のセッションを自動復元（15分ごと自動保存）
- Tokyo Night テーマ (TPM)

### プロジェクトランチャー（sesh + zoxide + fzf）

`prefix + o` で、実行中の tmux セッション・`zoxide` の訪問履歴・`sesh/sesh.toml` の定義をまとめて曖昧検索し、選んだプロジェクトを tmux セッションとして起動（既存なら復帰）します。

| 依存 | 役割 |
|---|---|
| `zoxide` | 訪れたディレクトリを頻度順に記憶（「最近のプロジェクト」の元データ） |
| `fzf` | 曖昧検索 UI |
| `sesh` | 候補を tmux セッションとして起動／復帰 |

```bash
brew install sesh zoxide fzf
```

`zoxide` は `.zshrc` で `eval "$(zoxide init zsh)"` を読み込む必要があります（`zsh/zshrc` に含まれています）。
ランチャー内のキー: `^a` 全候補 / `^t` tmux セッション / `^x` zoxide 履歴 / `^d` 選択セッションを kill。

### Ghostty
- フォント: MesloLGS NF
- テーマ: Tokyo Night
- 半透明背景 (opacity: 0.92)
- ネイティブ分割（旧 tmux `ide` の代替。GPU 描画で軽量・使い捨て前提。永続化が必要なものは tmux/sesh 側で管理）

#### 分割キーバインド

| キー | 動作 |
|---|---|
| `cmd+d` / `cmd+shift+d` | 右に分割 / 下に分割 |
| `cmd+alt+h/j/k/l` | ペイン移動（vim 風） |
| `cmd+ctrl+h/j/k/l` | ペインのリサイズ |
| `cmd+ctrl+=` | サイズ均等化 |
| `cmd+shift+enter` | ズーム（全画面トグル） |
| `cmd+w` | ペインを閉じる |

`cmd` 系のため tmux prefix (`Ctrl+t`) と衝突しません。
