#!/usr/bin/env bash
# リモートブランチの削除だけは自動承認させず、確認ダイアログに戻す。
#
# permissions.allow の Bash(git push:*) は `git push origin --delete br` にも
# マッチするため、「削除はローカルのみ許可」という意図を許可ルールだけでは
# 表現できない。PreToolUse から permissionDecision=ask を返して差を埋める。
# gh pr merge --delete-branch もリモートを消すので同じ扱いにする。
#
# 誤検知してもコストは確認ダイアログ1回なので、判定は緩め（安全側）に寄せている。
set -u

ask=0
cmd=$(jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

case "$cmd" in
  *git*push*)
    # --delete / -d、および `origin :branch` 形式の削除 refspec
    if printf '%s' "$cmd" \
      | grep -qE -- '(--delete([[:space:]]|=|$)|[[:space:]]-d([[:space:]]|$)|[[:space:]]:[A-Za-z0-9._/@{}-]+([[:space:]]|$))'; then
      ask=1
    fi
    ;;
esac

case "$cmd" in
  *--delete-branch*) ask=1 ;;
esac

if [ "$ask" -eq 1 ]; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"リモートブランチの削除に見えます。自動で許可してあるのはローカルブランチの削除までです。"}}'
fi
exit 0
