#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
failures=0

# dotfiles の中身を $HOME 以下にリンクする。
#
# ln -sf は、リンク先が「ディレクトリへのシンボリックリンク」の場合に張り替えず、
# そのディレクトリの中にリンクを作る（~/dotfiles/nvim/nvim が生える）。2回目以降の
# 実行で必ず踏むので -n を付ける。
#
# 実体のディレクトリが既にある場合は、中に潜り込ませず明示的に失敗させる。
# 黙って通すと「設定が効いていない」理由が分からなくなる。
link() {
  local src="$1" dest="$2"
  if [ -d "$dest" ] && [ ! -L "$dest" ]; then
    echo "skip: $dest は実体のディレクトリです。退避してから再実行してください" >&2
    failures=$((failures + 1))
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest" || { failures=$((failures + 1)); return 1; }
}

# neovim
link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# tmux
link "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

# ghostty
link "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# sesh（tmux セッションランチャー）
link "$DOTFILES_DIR/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"

# herdr（エージェント・マルチプレクサ / tmux後継）
# ディレクトリ全体はリンクしない（logs/sock/session.json 等のランタイムファイルが同居するため）
link "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# bin（自作コマンド）
link "$DOTFILES_DIR/bin/ide" "$HOME/bin/ide"
link "$DOTFILES_DIR/bin/tmux-clean" "$HOME/bin/tmux-clean"
link "$DOTFILES_DIR/bin/sesh-start" "$HOME/bin/sesh-start"

if [ "$failures" -gt 0 ]; then
  echo "Done（$failures 件リンクできませんでした）"
  exit 1
fi
echo "Done!"
