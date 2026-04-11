#!/usr/bin/env fish
# shell/fish/init.fish
# my-shell fish initialization
# This file sources all fish configuration components

if not set -q MY_SHELL_ROOT
    set -gx MY_SHELL_ROOT (cd (dirname (status -f))/../.. && pwd)
end

# env.fish loads unconditionally: PATH/LSCOLORS/CLICOLOR are safe and may be
# needed by non-interactive scripts and remote SSH command invocations.
source "$MY_SHELL_ROOT/shell/fish/env.fish"

# aliases.fish and prompt.fish are interactive-only: they override commands
# with wrappers that call tput/command coloring and only make sense at a
# terminal. Fish sources config.fish for non-interactive shells too (unlike
# bash/zsh), so we must guard explicitly or SSH command runs break.
if status is-interactive
    source "$MY_SHELL_ROOT/shell/fish/aliases.fish"
    source "$MY_SHELL_ROOT/shell/fish/prompt.fish"
end
