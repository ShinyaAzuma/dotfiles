#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

# zsh（個人設定は ~/.zshrc.local に分離するためリポジトリには入れない）
# 既存の実体ファイルがあればタイムスタンプ付きで退避してからリンクする
link_zsh() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up: $dest"
  fi
  ln -sf "$src" "$dest"
}
link_zsh "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
link_zsh "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"

# 個人設定は未作成時のみ雛形を置く（既存の値を潰さない）
if [ ! -f "$HOME/.zshrc.local" ]; then
  cp "$DOTFILES_DIR/zsh/zshrc.local.example" "$HOME/.zshrc.local"
  echo "created: ~/.zshrc.local （自分の値に書き換えてください）"
fi

# neovim
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# tmux
ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

# ghostty
ln -sf "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# sesh（tmux セッションランチャー）
mkdir -p "$HOME/.config/sesh"
ln -sf "$DOTFILES_DIR/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"

# herdr（エージェント・マルチプレクサ / tmux後継）
# ディレクトリ全体はリンクしない（logs/sock/session.json 等のランタイムファイルが同居するため）
mkdir -p "$HOME/.config/herdr"
ln -sf "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"

# bin（自作コマンド）
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES_DIR/bin/ide" "$HOME/bin/ide"
ln -sf "$DOTFILES_DIR/bin/tmux-clean" "$HOME/bin/tmux-clean"
ln -sf "$DOTFILES_DIR/bin/sesh-start" "$HOME/bin/sesh-start"
ln -sf "$DOTFILES_DIR/bin/claude-log-scan" "$HOME/bin/claude-log-scan"

# launchd（plist は $HOME を展開できないので、リンクではなく生成する）
AGENT="com.shinyaazuma.claude-log-scan"
AGENT_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$AGENT_DIR"
sed "s|__HOME__|$HOME|g" "$DOTFILES_DIR/launchd/$AGENT.plist" > "$AGENT_DIR/$AGENT.plist"
if launchctl print "gui/$(id -u)/$AGENT" >/dev/null 2>&1; then
  launchctl bootout "gui/$(id -u)/$AGENT" 2>/dev/null
fi
launchctl bootstrap "gui/$(id -u)" "$AGENT_DIR/$AGENT.plist" 2>/dev/null \
  && echo "loaded: $AGENT（毎日12:30にログを検査して通知）" \
  || echo "warn: $AGENT の登録に失敗しました"

echo "Done!"