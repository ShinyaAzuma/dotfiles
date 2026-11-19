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

# 既存の実体ファイルを黙って消さず、タイムスタンプ付きで退避してからリンクする。
# ~/.zshrc や ~/.claude/CLAUDE.md には手で書き足した内容が残っていることがあるため。
link_with_backup() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
    echo "backed up: $dest"
  fi
  link "$src" "$dest"
}

# zsh（個人設定は ~/.zshrc.local に分離するためリポジトリには入れない）
link_with_backup "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
link_with_backup "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"

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

# git（差分表示。~/.gitconfig は氏名・メールを持つので触らず XDG 側に置く）
link "$DOTFILES_DIR/git/config" "$HOME/.config/git/config"

# bin（自作コマンド）
link "$DOTFILES_DIR/bin/ide" "$HOME/bin/ide"
link "$DOTFILES_DIR/bin/tmux-clean" "$HOME/bin/tmux-clean"
link "$DOTFILES_DIR/bin/sesh-start" "$HOME/bin/sesh-start"
link "$DOTFILES_DIR/bin/claude-log-scan" "$HOME/bin/claude-log-scan"

# Claude Code（個人 ~/.claude と Rewire ~/.claude-rewire の両プロファイルに配る）
#
# - CLAUDE.md: 公開してよい共通ルールだけをリンクする。運用ルールなど公開したくない
#   ものは ~/.claude/CLAUDE.private.md に置き、CLAUDE.md から @ import する
#   （Rewire 側も同じファイルを読む）
# - settings.json: Claude Code 自身が /permissions などで書き込むファイルなので、
#   リンクやコピーにせず claude/settings.json のキーだけを上書きマージする。
#   permissions や autoMode（プロジェクト固有の構成を含む）はローカルに残る。
#   jq の * は配列を丸ごと置き換えるため、hooks.PreToolUse はこちらの内容で上書きされる
#   （hooks.SessionStart の herdr 連携など、管理していないイベントは残る）
# - ~/.claude-rewire はログイン済みのマシンにだけあるので、無ければ作らない
merge_claude_settings() {
  local dest="$1/settings.json" shared tmp
  if ! command -v jq >/dev/null 2>&1; then
    echo "skip: jq が無いため $dest をマージできません" >&2
    failures=$((failures + 1)); return 1
  fi
  shared=$(jq --arg d "$DOTFILES_DIR" \
    'walk(if type == "string" then gsub("__DOTFILES__"; $d) else . end)' \
    "$DOTFILES_DIR/claude/settings.json") || { failures=$((failures + 1)); return 1; }

  if [ ! -f "$dest" ]; then
    printf '%s\n' "$shared" > "$dest"
    return
  fi
  tmp=$(mktemp "$1/.settings.json.XXXXXX")
  if ! jq -s '.[0] * .[1]' "$dest" <(printf '%s' "$shared") > "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    echo "skip: $dest を JSON として読めません。直してから再実行してください" >&2
    failures=$((failures + 1)); return 1
  fi
  if cmp -s <(jq -S . "$dest") <(jq -S . "$tmp"); then
    rm -f "$tmp"
    return
  fi
  cp -p "$dest" "$dest.bak.$(date +%Y%m%d%H%M%S)"
  chmod "$(stat -f %Lp "$dest")" "$tmp"   # mktemp は 600 で作るので元の権限に揃える
  mv "$tmp" "$dest"
  echo "updated: ${dest}（変更前は .bak に退避）"
}

for claude_dir in "$HOME/.claude" "$HOME/.claude-rewire"; do
  if [ "$claude_dir" != "$HOME/.claude" ] && [ ! -d "$claude_dir" ]; then
    continue
  fi
  mkdir -p "$claude_dir"
  link_with_backup "$DOTFILES_DIR/claude/CLAUDE.md" "$claude_dir/CLAUDE.md"
  merge_claude_settings "$claude_dir"
done

if [ ! -f "$HOME/.claude/CLAUDE.private.md" ]; then
  cp "$DOTFILES_DIR/claude/CLAUDE.private.md.example" "$HOME/.claude/CLAUDE.private.md"
  echo "created: ~/.claude/CLAUDE.private.md （公開したくないルールを書いてください）"
fi

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
    && echo "loaded: ${AGENT}（毎日12:30にログを検査して通知）" \
    || echo "warn: $AGENT の登録に失敗しました"
fi

if [ "$failures" -gt 0 ]; then
  echo "Done（$failures 件リンクできませんでした）"
  exit 1
fi
echo "Done!"
