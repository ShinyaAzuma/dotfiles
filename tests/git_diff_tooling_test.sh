#!/usr/bin/env bash
# 差分表示ツール（delta / difftastic）の設定を検証する。
# git の設定ファイルは実際に git config --file で読んで確かめる。
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
config="$repo_root/git/config"
failures=0

ok()   { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; failures=$((failures + 1)); }

if [ ! -f "$config" ]; then
  fail "git/config が存在する"
  exit 1
fi
ok "git/config が存在する"

if git config --file "$config" --list >/dev/null 2>&1; then
  ok "git が設定として読める"
else
  fail "git が設定として読める"
  exit 1
fi

get() { git config --file "$config" --get "$1" 2>/dev/null; }

# delta: git diff / show / log の既定の見た目
case "$(get core.pager)" in
  *delta*) ok "core.pager に delta を使う" ;;
  *) fail "core.pager に delta を使う（実際: $(get core.pager)）" ;;
esac

case "$(get interactive.diffFilter)" in
  *delta*) ok "interactive.diffFilter に delta を使う（git add -p 用）" ;;
  *) fail "interactive.diffFilter に delta を使う（実際: $(get interactive.diffFilter)）" ;;
esac

# difftastic: 構文単位の diff。AI のリファクタ差分で効く
case "$(get difftool.difftastic.cmd)" in
  *difft*) ok "difftastic が difftool として登録されている" ;;
  *) fail "difftastic が difftool として登録されている（実際: $(get difftool.difftastic.cmd)）" ;;
esac

# 毎回 --tool を打たなくて済むよう alias を用意する
if [ -n "$(get alias.dft)" ]; then
  ok "difftastic の alias (git dft) がある"
else
  fail "difftastic の alias (git dft) がある"
fi

# delta は既定だと差分の由来が追いにくいので、移動検出と行番号を有効にする
[ "$(get delta.line-numbers)" = "true" ] \
  && ok "delta で行番号を出す" \
  || fail "delta で行番号を出す（実際: $(get delta.line-numbers)）"

# setup.sh からリンクされること。
# ~/.gitconfig は氏名・メールを持つので触らず、XDG 側に置いて共存させる
if grep -q 'git/config' "$repo_root/setup.sh"; then
  ok "setup.sh が git/config をリンクする"
else
  fail "setup.sh が git/config をリンクする"
fi

# コメントでの言及は許す。実際に操作している行だけを見る
if grep -vE '^[[:space:]]*#' "$repo_root/setup.sh" | grep -qE '\.gitconfig'; then
  fail "~/.gitconfig には手を出さない"
else
  ok "~/.gitconfig には手を出さない"
fi

# lazygit からも delta を使う（レビュー導線で見た目を揃える）
case "$(grep -A3 'pagers:' "$repo_root/lazygit/config.yml" 2>/dev/null)" in
  *delta*) ok "lazygit の pager に delta を使う" ;;
  *) fail "lazygit の pager に delta を使う" ;;
esac

# 旧形式の paging: で書くと lazygit が起動時にこのファイルを書き換えて移行する。
# dotfiles からの symlink なので、リポジトリに勝手な差分が出てしまう
if grep -qE '^[[:space:]]+paging:' "$repo_root/lazygit/config.yml"; then
  fail "lazygit の設定が旧形式 (paging:) になっていない"
else
  ok "lazygit の設定が旧形式 (paging:) になっていない"
fi

# 新しい環境でも入るように Brewfile に残す
for pkg in git-delta difftastic; do
  if grep -q "\"$pkg\"" "$repo_root/Brewfile"; then
    ok "Brewfile に $pkg がある"
  else
    fail "Brewfile に $pkg がある"
  fi
done

if [ "$failures" -eq 0 ]; then
  echo "All tests passed."
else
  echo "$failures test(s) failed."
  exit 1
fi
