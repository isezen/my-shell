#!/usr/bin/env fish
# shell/fish/init.fish
# my-shell fish initialization
# This file sources all fish configuration components

# Resolve the directory of this file so sibling sources work both when run
# from the repo layout (`<repo>/shell/fish/`) and the installed layout
# (`~/.my-shell/fish/`). MY_SHELL_ROOT is kept for downstream consumers but
# is NOT used to locate siblings — that was brittle across layouts.
set -l _init_dir (dirname (status -f))

if not set -q MY_SHELL_ROOT
    set -gx MY_SHELL_ROOT (cd "$_init_dir/../.." && pwd)
end

# env.fish loads unconditionally: PATH/LSCOLORS/CLICOLOR are safe and may be
# needed by non-interactive scripts and remote SSH command invocations.
source "$_init_dir/env.fish"

# aliases.fish and prompt.fish are interactive-only: they override commands
# with wrappers that call tput/command coloring and only make sense at a
# terminal. Fish sources config.fish for non-interactive shells too (unlike
# bash/zsh), so we must guard explicitly or SSH command runs break.
if status is-interactive
    source "$_init_dir/aliases.fish"
    source "$_init_dir/prompt.fish"
end
