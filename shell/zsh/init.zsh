#!/bin/zsh
# my-shell zsh initialization
# This file sources all zsh configuration components

MY_SHELL_ROOT="${MY_SHELL_ROOT:-$(cd "$(dirname "${(%):-%x}")/../.." && pwd)}"

# Source components
source "$MY_SHELL_ROOT/shell/zsh/env.zsh"
source "$MY_SHELL_ROOT/shell/zsh/aliases.zsh"
source "$MY_SHELL_ROOT/shell/zsh/prompt.zsh"

