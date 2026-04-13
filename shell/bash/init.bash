#!/bin/bash
# shell/bash/init.bash
# my-shell bash initialization
# This file sources all bash configuration components

# Resolve this file's directory so sibling sources work both in the repo
# layout (`<repo>/shell/bash/`) and the installed layout (`~/.my-shell/bash/`).
# MY_SHELL_ROOT is preserved for downstream consumers but is not used for
# locating siblings — that was brittle across layouts.
__my_shell_init_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MY_SHELL_ROOT="${MY_SHELL_ROOT:-$(cd "$__my_shell_init_dir/../.." && pwd)}"

# Source components
# shellcheck disable=SC1091
source "$__my_shell_init_dir/env.bash"
# shellcheck disable=SC1091
source "$__my_shell_init_dir/aliases.bash"
# shellcheck disable=SC1091
source "$__my_shell_init_dir/prompt.bash"

unset __my_shell_init_dir
