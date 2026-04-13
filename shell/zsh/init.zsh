#!/bin/zsh
# shell/zsh/init.zsh
# my-shell zsh initialization
# This file sources all zsh configuration components

# Resolve this file's directory so sibling sources work both in the repo
# layout (`<repo>/shell/zsh/`) and the installed layout (`~/.my-shell/zsh/`).
# MY_SHELL_ROOT is preserved for downstream consumers but is not used for
# locating siblings — that was brittle across layouts.
__my_shell_init_dir="$(cd "$(dirname "${(%):-%x}")" && pwd)"
MY_SHELL_ROOT="${MY_SHELL_ROOT:-$(cd "$__my_shell_init_dir/../.." && pwd)}"

# Source components
source "$__my_shell_init_dir/env.zsh"
source "$__my_shell_init_dir/aliases.zsh"
source "$__my_shell_init_dir/prompt.zsh"

unset __my_shell_init_dir
