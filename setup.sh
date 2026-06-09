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

echo "Done!"