#!/usr/bin/env fish
# my-shell fish initialization
# This file sources all fish configuration components

if not set -q MY_SHELL_ROOT
    set -gx MY_SHELL_ROOT (cd (dirname (status -f))/../.. && pwd)
end

# Source components
source "$MY_SHELL_ROOT/shell/fish/env.fish"
source "$MY_SHELL_ROOT/shell/fish/aliases.fish"
source "$MY_SHELL_ROOT/shell/fish/prompt.fish"

