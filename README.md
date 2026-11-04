# dotfiles

macOS 向けの個人用 dotfiles です。

## 構成

| ディレクトリ/ファイル | 説明 |
|---|---|
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

- `~/dotfiles/nvim` → `~/.config/nvim`
- `~/dotfiles/tmux.conf` → `~/.tmux.conf`
- `~/dotfiles/ghostty` → `~/.config/ghostty`

## 主な特徴

### Neovim
- lazy.nvim によるプラグイン管理
- LSP / Treesitter / fzf / oil.nvim など
- git レビュー: gitsigns / diffview / lazygit

### コードレビュー（AI が書いた差分を読む）

エージェントの変更を自分で確認するための導線です。流し見は lazygit、ブランチ単位の通読は diffview を使います。

| キー | 動作 |
|---|---|
| `<leader>Gw` | 未コミットの変更を diffview で開く（AI が書いた直後の確認） |
| `<leader>Gd` | `main...HEAD` を diffview で開く（PR 単位の通読） |
| `<leader>Gf` | 現在のファイルの変更履歴 |
| `<leader>Gq` | diffview を閉じる |
| `<leader>Gg` | lazygit を開く（hunk 単位で stage / discard） |
| `]c` / `[c` | 次 / 前の hunk へ（diffview の差分内では組み込み動作を維持） |
| `<leader>hp` | hunk をプレビュー |
| `<leader>hr` | hunk を取り消す（ビジュアル選択時は選択範囲のみ） |
| `<leader>hb` | 行の blame を表示 |

herdr 側では `prefix + alt + g` でも lazygit をペインで開けます（エージェントの隣に並べる用）。

`<leader>` は `Space` です。git 系を `<leader>G`（大文字）にまとめているのは、`<leader>g` が Telescope live_grep に割り当て済みで、`<leader>gX` を足すと live_grep が `timeoutlen` 分待たされるためです。

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

`zoxide` は `.zshrc` で `eval "$(zoxide init zsh)"` を読み込む必要があります（`.zshrc` は本リポジトリ管理外）。
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
