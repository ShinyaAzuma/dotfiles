#!/usr/bin/env bash
# setup.sh の回帰テスト。`bash tests/setup_test.sh` で実行する。
#
# 目的:
#   1. 新規インストール（~/.config すら無い状態）で全てのリンクが張れること
#   2. 再実行時に、既存のリンクを「張り替える」こと
#      ln -sf はリンク先がディレクトリへのシンボリックリンクだと、張り替えずに
#      その中にリンクを作る（~/dotfiles/nvim/nvim が生える）。-n が必要。
#   3. リンク先が実体のディレクトリの場合、中に潜り込まず明示的に失敗すること
#
# HOME を差し替えたサンドボックスで setup.sh を丸ごと実行して検証する。

SETUP="$(cd "$(dirname "$0")/.." && pwd)/setup.sh"
failed=0
ok()   { printf '  ok   - %s\n' "$1"; }
fail() { printf '  FAIL - %s\n' "$1"; failed=1; }

# リンクを張る対象のダミー dotfiles ツリーを作る
make_sandbox() {
  local home; home=$(mktemp -d)
  local d="$home/dotfiles"
  mkdir -p "$d/nvim" "$d/ghostty" "$d/sesh" "$d/herdr" "$d/bin"
  touch "$d/tmux.conf" "$d/sesh/sesh.toml" "$d/herdr/config.toml"
  touch "$d/bin/ide" "$d/bin/tmux-clean" "$d/bin/sesh-start"
  cp "$SETUP" "$d/setup.sh"
  printf '%s' "$home"
}

run_setup() { env HOME="$1" bash "$1/dotfiles/setup.sh" >/dev/null 2>&1; }

assert_link() {
  local label="$1" dest="$2" want="$3"
  if [ ! -L "$dest" ]; then fail "$label: $dest がシンボリックリンクではない"; return; fi
  local got; got=$(readlink "$dest")
  [ "$got" = "$want" ] && ok "$label" || fail "$label: $got を指している（期待: $want）"
}

echo "新規インストール"
HOME_A=$(make_sandbox)
run_setup "$HOME_A"
assert_link "nvim をリンクする（~/.config が無い状態から）" "$HOME_A/.config/nvim"       "$HOME_A/dotfiles/nvim"
assert_link "ghostty をリンクする"                          "$HOME_A/.config/ghostty"    "$HOME_A/dotfiles/ghostty"
assert_link "tmux.conf をリンクする"                        "$HOME_A/.tmux.conf"         "$HOME_A/dotfiles/tmux.conf"
assert_link "sesh.toml をリンクする"                        "$HOME_A/.config/sesh/sesh.toml"   "$HOME_A/dotfiles/sesh/sesh.toml"
assert_link "herdr config.toml をリンクする"                "$HOME_A/.config/herdr/config.toml" "$HOME_A/dotfiles/herdr/config.toml"
assert_link "bin/ide をリンクする"                          "$HOME_A/bin/ide"            "$HOME_A/dotfiles/bin/ide"

echo
echo "既にディレクトリへのリンクが張られている状態での再実行"
# 実行順に依存させず、前提を明示的に作る。run_setup の回数で結果が変わると
# 本命のバグ（張り替えずに中へ潜り込む）を踏み外す。
HOME_C=$(make_sandbox)
mkdir -p "$HOME_C/.config"
ln -s "$HOME_C/dotfiles/nvim"    "$HOME_C/.config/nvim"
ln -s "$HOME_C/dotfiles/ghostty" "$HOME_C/.config/ghostty"
run_setup "$HOME_C"
assert_link "nvim のリンクを張り替える"    "$HOME_C/.config/nvim"    "$HOME_C/dotfiles/nvim"
assert_link "ghostty のリンクを張り替える" "$HOME_C/.config/ghostty" "$HOME_C/dotfiles/ghostty"
# 本命: リンク先ディレクトリの中に自己参照リンクを生やしていないこと
for leaked in "$HOME_C/dotfiles/nvim/nvim" "$HOME_C/dotfiles/ghostty/ghostty"; do
  [ -e "$leaked" ] && fail "リンク先の中に $leaked を作ってしまった" \
                   || ok "$(basename "$(dirname "$leaked")") の中にリンクを作らない"
done

echo
echo "二重実行しても壊れない"
run_setup "$HOME_A"
assert_link "nvim（2回目）"    "$HOME_A/.config/nvim"    "$HOME_A/dotfiles/nvim"
assert_link "ghostty（2回目）" "$HOME_A/.config/ghostty" "$HOME_A/dotfiles/ghostty"

echo
echo "リンク先が実体のディレクトリの場合"
HOME_B=$(make_sandbox)
mkdir -p "$HOME_B/.config/nvim"
touch "$HOME_B/.config/nvim/init.lua"      # 既存の設定が入っている想定
run_setup "$HOME_B"
[ -e "$HOME_B/.config/nvim/nvim" ] \
  && fail "実体ディレクトリの中にリンクを作ってしまった" \
  || ok "実体ディレクトリの中にリンクを作らない"
[ -f "$HOME_B/.config/nvim/init.lua" ] \
  && ok "既存の設定を壊さない" \
  || fail "既存の設定が消えた"
if env HOME="$HOME_B" bash "$HOME_B/dotfiles/setup.sh" 2>&1 | grep -q 'nvim'; then
  ok "実体ディレクトリがあることを警告する"
else
  fail "実体ディレクトリがあっても黙って通過する"
fi

rm -rf "$HOME_A" "$HOME_B" "$HOME_C"
echo
[ "$failed" -eq 0 ] && echo "すべて通過" || echo "失敗あり"
exit "$failed"
