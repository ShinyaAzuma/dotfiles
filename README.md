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

### tmux
- プレフィックスキー: `Ctrl+t`
- vim 風ペイン移動 (`h/j/k/l`)
- Lazygit ポップアップ (`prefix + g`)
- Claude Code ポップアップ (`prefix + a`)
- Tokyo Night テーマ (TPM)

### Ghostty
- フォント: MesloLGS NF
- テーマ: Tokyo Night
- 半透明背景 (opacity: 0.92)
