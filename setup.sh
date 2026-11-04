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

# zsh だけは、既存の実体ファイルを黙って消さずタイムスタンプ付きで退避する。
# ~/.zshrc には手で書き足した内容が残っていることがあるため。
link_zsh() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up: $dest"
  fi
  link "$src" "$dest"
}

# zsh（個人設定は ~/.zshrc.local に分離するためリポジトリには入れない）
link_zsh "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
link_zsh "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"

# 個人設定は未作成時のみ雛形を置く（既存の値を潰さない）
if [ ! -f "$HOME/.zshrc.local" ]; then
  cp "$DOTFILES_DIR/zsh/zshrc.local.example" "$HOME/.zshrc.local"
  echo "created: ~/.zshrc.local （自分の値に書き換えてください）"
fi

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

# lazygit（差分レビュー）
# ディレクトリ全体はリンクしない（state.yml 等のランタイムファイルが同居するため）
link "$DOTFILES_DIR/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"

# bin（自作コマンド）
link "$DOTFILES_DIR/bin/ide" "$HOME/bin/ide"
link "$DOTFILES_DIR/bin/tmux-clean" "$HOME/bin/tmux-clean"
link "$DOTFILES_DIR/bin/sesh-start" "$HOME/bin/sesh-start"
link "$DOTFILES_DIR/bin/claude-log-scan" "$HOME/bin/claude-log-scan"

# launchd（plist は $HOME を展開できないので、リンクではなく生成する）
#
# launchctl は HOME ではなく実ユーザーのセッションに作用する。HOME を差し替えた
# サンドボックス（tests/setup_test.sh）から呼ぶと本物のエージェントが登録されて
# しまうため、テストからは DOTFILES_SKIP_LAUNCHD=1 で抑止する。
if [ -z "${DOTFILES_SKIP_LAUNCHD:-}" ]; then
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
fi

if [ "$failures" -gt 0 ]; then
  echo "Done（$failures 件リンクできませんでした）"
  exit 1
fi
echo "Done!"
