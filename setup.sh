#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"

# neovim
ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# tmux
ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"

# ghostty
ln -sf "$DOTFILES_DIR/ghostty" "$HOME/.config/ghostty"

# sesh（tmux セッションランチャー）
mkdir -p "$HOME/.config/sesh"
ln -sf "$DOTFILES_DIR/sesh/sesh.toml" "$HOME/.config/sesh/sesh.toml"

# bin（自作コマンド）
mkdir -p "$HOME/bin"
ln -sf "$DOTFILES_DIR/bin/ide" "$HOME/bin/ide"
ln -sf "$DOTFILES_DIR/bin/tmux-clean" "$HOME/bin/tmux-clean"
ln -sf "$DOTFILES_DIR/bin/sesh-start" "$HOME/bin/sesh-start"

echo "Done!"