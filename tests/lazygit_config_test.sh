#!/usr/bin/env bash
# lazygit/config.yml を検証する。lazygit 本体は起動せず、設定の内容だけを見る。
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
config="$repo_root/lazygit/config.yml"
failures=0

ok()   { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; failures=$((failures + 1)); }

if [ ! -f "$config" ]; then
  fail "lazygit/config.yml が存在する"
  exit 1
fi
ok "lazygit/config.yml が存在する"

# YAML として壊れていないこと
if python3 -c "import yaml,sys; yaml.safe_load(open('$config'))" 2>/dev/null; then
  ok "YAML として読める"
else
  fail "YAML として読める"
fi

# lazygit 0.62 で confirmInEditor が meta+enter (cmd+enter) に変わった。
# cmd 系は端末から TUI へ届く保証がないため、alt+enter を明示的に戻しておく。
confirm="$(python3 -c "
import yaml
c = yaml.safe_load(open('$config')) or {}
v = c.get('keybinding', {}).get('universal', {}).get('confirmInEditor')
print(v if v is not None else '')
" 2>/dev/null)"

case "$confirm" in
  *"alt+enter"*) ok "confirmInEditor に alt+enter が含まれる" ;;
  *) fail "confirmInEditor に alt+enter が含まれる（実際: ${confirm:-未設定}）" ;;
esac

case "$confirm" in
  *"ctrl+s"*) ok "confirmInEditor に ctrl+s の控えがある" ;;
  *) fail "confirmInEditor に ctrl+s の控えがある（実際: ${confirm:-未設定}）" ;;
esac

# setup.sh からリンクされること。
# ディレクトリごとリンクしない（state.yml 等のランタイムファイルが同居するため）
if grep -q 'lazygit/config.yml' "$repo_root/setup.sh"; then
  ok "setup.sh が config.yml をリンクする"
else
  fail "setup.sh が config.yml をリンクする"
fi

if grep -qE 'ln -sf "\$DOTFILES_DIR/lazygit"[[:space:]]' "$repo_root/setup.sh"; then
  fail "lazygit ディレクトリ全体はリンクしない"
else
  ok "lazygit ディレクトリ全体はリンクしない"
fi

if [ "$failures" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$failures test(s) failed."
  exit 1
fi
