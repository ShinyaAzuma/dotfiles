#!/usr/bin/env bash
# claude/hooks/ask-remote-branch-delete.sh の回帰テスト。
# `bash tests/ask_remote_branch_delete_test.sh` で実行する。
#
# この hook は PreToolUse で Bash コマンドを受け取り、リモートブランチの削除に
# 見えるときだけ permissionDecision=ask を返す。ローカルブランチの削除や通常の
# push は素通しする（何も出力しない）こと。
#
# HOOK を差し替えると別の場所のスクリプトを検査できる（移設前の挙動確認用）。
set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="${HOOK:-$repo_root/claude/hooks/ask-remote-branch-delete.sh}"
failures=0

ok()   { printf 'ok   - %s\n' "$1"; }
fail() { printf 'FAIL - %s\n' "$1"; failures=$((failures + 1)); }

run_hook() {
  jq -n --arg c "$1" '{tool_name: "Bash", tool_input: {command: $c}}' | bash "$HOOK"
}

expect_ask() {
  local out; out=$(run_hook "$1")
  if [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)" = "ask" ]; then
    ok "確認を求める: $1"
  else
    fail "確認を求めない: $1"
  fi
}

expect_pass() {
  local out; out=$(run_hook "$1")
  [ -z "$out" ] && ok "素通しする: $1" || fail "素通ししない: $1（出力: $out）"
}

if [ ! -f "$HOOK" ]; then
  fail "$HOOK が存在する"
  exit 1
fi

echo "リモートブランチの削除"
expect_ask 'git push origin --delete feature/x'
expect_ask 'git push --delete origin feature/x'
expect_ask 'git push origin -d feature/x'
expect_ask 'git push origin :feature/x'
expect_ask 'gh pr merge 12 --squash --delete-branch'

echo
echo "削除ではない操作"
expect_pass 'git push origin feature/x'
expect_pass 'git push -u origin feat-d'
expect_pass 'git push --force-with-lease origin feature/x'
expect_pass 'git branch -d feature/x'
expect_pass 'git branch -D feature/x'
expect_pass 'gh pr merge 12 --squash'
expect_pass 'ls -la'

echo
[ "$failures" -eq 0 ] && echo "すべて通過" || echo "$failures 件失敗"
exit $((failures > 0))
