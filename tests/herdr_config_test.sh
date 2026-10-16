#!/usr/bin/env bash
# herdr/config.toml の起動コマンドを検証する。
# herdr 本体は起動せず、設定ファイルの内容だけを見る。
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
config="$repo_root/herdr/config.toml"
failures=0

ok()   { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; failures=$((failures + 1)); }

# [[keys.command]] ブロックを key で引いて command の値だけを返す
command_for() {
  awk -v want="$1" '
    /^\[\[keys\.command\]\]/ { in_block = 1; key = ""; cmd = ""; next }
    in_block && /^key *=/     { key = $0 }
    in_block && /^command *=/ { sub(/^command *= *"/, ""); sub(/"$/, ""); cmd = $0 }
    in_block && /^[[:space:]]*$/ {
      in_block = 0
      if (index(key, "\"" want "\"")) { print cmd; found = 1; exit }
    }
    END { if (!found && in_block && index(key, "\"" want "\"")) print cmd }
  ' "$config"
}

if [ ! -f "$config" ]; then
  fail "herdr/config.toml が存在する"
  exit 1
fi
ok "herdr/config.toml が存在する"

default_cmd="$(command_for 'prefix+a')"
rewire_cmd="$(command_for 'prefix+shift+a')"

[ -n "$default_cmd" ] \
  && ok "prefix+a に起動コマンドがある" \
  || fail "prefix+a に起動コマンドがある"

[ -n "${rewire_cmd}" ] \
  && ok "prefix+shift+a に起動コマンドがある" \
  || fail "prefix+shift+a に起動コマンドがある"

# default は個人アカウント。CLAUDE_CONFIG_DIR を指定してはいけない
case "$default_cmd" in
  *CLAUDE_CONFIG_DIR*) fail "prefix+a は CLAUDE_CONFIG_DIR を指定しない" ;;
  *) ok "prefix+a は CLAUDE_CONFIG_DIR を指定しない" ;;
esac

# Rewire は .claude-rewire を使う
case "${rewire_cmd}" in
  *"CLAUDE_CONFIG_DIR=$HOME/.claude-rewire"*|*"CLAUDE_CONFIG_DIR=/Users/shinyaazuma/.claude-rewire"*)
    ok "prefix+shift+a は .claude-rewire を使う" ;;
  *) fail "prefix+shift+a は .claude-rewire を使う（実際: ${rewire_cmd}）" ;;
esac

# Rewire 側は claudeInChromeDefaultEnabled が落ちても繋がるよう --chrome を明示する
case "${rewire_cmd}" in
  *--chrome*) ok "prefix+shift+a は --chrome で Claude in Chrome を有効にする" ;;
  *) fail "prefix+shift+a は --chrome で Claude in Chrome を有効にする（実際: ${rewire_cmd}）" ;;
esac

if [ "$failures" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$failures test(s) failed."
  exit 1
fi
