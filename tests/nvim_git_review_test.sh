#!/usr/bin/env bash
# nvim の git レビュー用 spec を検証する薄いラッパー。
set -u
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
exec nvim -l "$repo_root/tests/nvim_git_review_test.lua"
