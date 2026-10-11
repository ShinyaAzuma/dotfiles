#!/usr/bin/env zsh
# zsh/zshrc の回帰テスト。`zsh zsh/test/zshrc_test.zsh` で実行する。
#
# 目的:
#   1. 公開リポジトリに個人情報リテラルが混入していないこと
#   2. 個人情報を ~/.zshrc.local へ切り出した際の「挙動不変」
#      （gitMain/gitPri が従来と同じ値を git に渡すこと）
#   3. 個人設定が未投入でも壊れないこと

set -u
ZSHRC="${0:A:h}/../zshrc"
failed=0

ok()   { print -r -- "  ok   - $1" }
fail() { print -r -- "  FAIL - $1"; failed=1 }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then ok "$desc"
  else fail "$desc"; print -r -- "         expected: $expected"; print -r -- "         actual:   $actual"; fi
}

print -r -- "== 1. 個人情報リテラルの混入チェック =="

if grep -qE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$ZSHRC"; then
  fail "メールアドレスらしき文字列が zsh/zshrc に含まれている"
  grep -nE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$ZSHRC"
else
  ok "メールアドレスは含まれていない"
fi

if grep -q '/Users/' "$ZSHRC"; then
  fail "ホームディレクトリの絶対パスがハードコードされている"
  grep -n '/Users/' "$ZSHRC"
else
  ok "ホームディレクトリは \$HOME で参照している"
fi

print -r -- "== 2. gitMain / gitPri の挙動不変 =="

# git config を差し替えて、実際に渡る引数を捕捉する
(
  GIT_WORK_NAME="WorkName";  GIT_WORK_EMAIL="work@example.com"
  GIT_PRIV_NAME="PrivName";  GIT_PRIV_EMAIL="priv@example.org"
  captured=()
  git() { captured+=("$*") }

  # 関数定義だけを取り出して評価する（zshrc 全体は副作用が大きいため）
  eval "$(sed -n '/^function gitMain()/,/^}/p;/^function gitPri()/,/^}/p' "$ZSHRC")"

  captured=(); gitMain >/dev/null 2>&1
  [[ "${captured[1]}" == "config --global user.name WorkName" ]] \
    && print "  ok   - gitMain が user.name に GIT_WORK_NAME を渡す" \
    || { print "  FAIL - gitMain user.name: ${captured[1]}"; exit 1 }
  [[ "${captured[2]}" == "config --global user.email work@example.com" ]] \
    && print "  ok   - gitMain が user.email に GIT_WORK_EMAIL を渡す" \
    || { print "  FAIL - gitMain user.email: ${captured[2]}"; exit 1 }

  captured=(); gitPri >/dev/null 2>&1
  [[ "${captured[1]}" == "config --global user.name PrivName" ]] \
    && print "  ok   - gitPri が user.name に GIT_PRIV_NAME を渡す" \
    || { print "  FAIL - gitPri user.name: ${captured[1]}"; exit 1 }
  [[ "${captured[2]}" == "config --global user.email priv@example.org" ]] \
    && print "  ok   - gitPri が user.email に GIT_PRIV_EMAIL を渡す" \
    || { print "  FAIL - gitPri user.email: ${captured[2]}"; exit 1 }
) || failed=1

print -r -- "== 3. 個人設定が未投入でも壊れないこと =="

(
  unset GH_WORK_USER
  eval "$(sed -n '/^ghpr() {/,/^}/p' "$ZSHRC")"
  out=$(ghpr 2>&1); rc=$?
  [[ $rc -ne 0 ]] \
    && print "  ok   - GH_WORK_USER 未設定なら ghpr は非ゼロ終了する" \
    || { print "  FAIL - GH_WORK_USER 未設定でも ghpr が成功した"; exit 1 }
  [[ "$out" == *"GH_WORK_USER"* ]] \
    && print "  ok   - 未設定時に設定方法を案内する" \
    || { print "  FAIL - 案内メッセージがない: $out"; exit 1 }
) || failed=1

print -r -- ""
if (( failed )); then print -r -- "FAILED"; exit 1; else print -r -- "All tests passed."; fi
