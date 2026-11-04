#!/usr/bin/env zsh
# PATH 解決の回帰テスト。`zsh zsh/test/path_test.zsh` で実行する。
#
# 目的:
#   1. /usr/local/bin が /usr/bin より後ろにあること
#      （Rosetta 消滅後、/usr/local の x86_64 バイナリが実行不能なため）
#   2. かつて /usr/local 側に潰されていたコマンドが、このマシンで実行可能な
#      アーキテクチャのバイナリに解決されること
#   3. nvm のデフォルト版のパスが実在すること（v の重複バグの回帰防止）
#
# 注意: PATH は親プロセスから継承されると検証にならないため、必ず env -i で
#       クリーンなログインシェルを起こして組み立て直す。

ZSHRC="${0:A:h}/../zshrc"
ZPROFILE="${0:A:h}/../zprofile"
failed=0
ok()   { print -r -- "  ok   - $1" }
fail() { print -r -- "  FAIL - $1"; failed=1 }

ZDOTDIR_TMP=$(mktemp -d)
cp "$ZSHRC" "$ZDOTDIR_TMP/.zshrc"
cp "$ZPROFILE" "$ZDOTDIR_TMP/.zprofile"
resolved_path=$(env -i HOME="$HOME" TERM=dumb ZDOTDIR="$ZDOTDIR_TMP" \
  /bin/zsh -li -c 'print -l $path' 2>/dev/null)
rm -rf "$ZDOTDIR_TMP"

if [[ -z $resolved_path ]]; then
  print -r -- "  FAIL - ログインシェルから PATH を取得できなかった"
  exit 1
fi
path_joined=${(j.:.)${(f)resolved_path}}

# このマシンで実行できないバイナリか判定する。
# universal / arm64 / スクリプトは可、x86_64 単独の Mach-O だけを不可とする。
runnable() {
  local info; info=$(file -L "$1" 2>/dev/null)
  [[ $info == *Mach-O* ]] || return 0           # スクリプト等は対象外
  [[ $info == *arm64* ]] && return 0
  return 1
}

print -r -- "== 1. /usr/local/bin は /usr/bin より後ろ =="

idx_local=$(print -r -- "$resolved_path" | grep -nx '/usr/local/bin' | cut -d: -f1 | head -1)
idx_usr=$(print -r -- "$resolved_path"   | grep -nx '/usr/bin'       | cut -d: -f1 | head -1)

if [[ -z $idx_usr ]]; then
  fail "/usr/bin が PATH にない"
elif [[ -z $idx_local ]]; then
  ok "/usr/local/bin は PATH にない（それでも可）"
elif (( idx_local > idx_usr )); then
  ok "/usr/local/bin ($idx_local) は /usr/bin ($idx_usr) より後ろ"
else
  fail "/usr/local/bin ($idx_local) が /usr/bin ($idx_usr) より前にある"
fi

print -r -- "== 2. 主要コマンドが実行可能なバイナリに解決される =="

# Rosetta 消滅で /usr/local 側が壊れていたコマンド群
for cmd in git git-upload-pack jq openssl stdbuf tclsh wish; do
  resolved=$(PATH="$path_joined" command -v $cmd 2>/dev/null)
  if [[ -z $resolved ]]; then
    fail "$cmd が PATH 上に見つからない"
  elif runnable "$resolved"; then
    ok "$cmd -> $resolved"
  else
    fail "$cmd -> $resolved (このマシンで実行できない x86_64 バイナリ)"
  fi
done

print -r -- "== 3. nvm のデフォルト版パスが実在する =="

nvm_entry=$(print -r -- "$resolved_path" | grep '/\.nvm/versions/node/' | head -1)
if [[ -z $nvm_entry ]]; then
  ok "nvm のパスは PATH に入っていない（nvm 未使用環境）"
elif [[ -d $nvm_entry ]]; then
  ok "nvm パスが実在する: $nvm_entry"
else
  fail "nvm パスが存在しない: $nvm_entry"
fi

if print -r -- "$resolved_path" | grep -q '/node/vv'; then
  fail "nvm のバージョンに v が重複している"
else
  ok "nvm のバージョンに v の重複がない"
fi

print -r -- ""
if (( failed )); then print -r -- "FAILED"; exit 1; else print -r -- "All tests passed."; fi
