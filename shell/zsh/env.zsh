#!/bin/zsh
# Zsh environment settings (history, dircolors, etc.)

export CLICOLOR=1

# History behavior (bash.sh equivalent)
HISTSIZE=1000
SAVEHIST=2000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY

# dircolors (GNU ls)
if command ls --version >/dev/null 2>&1; then
  if [ ! -f ~/.dircolors ] && command -v curl >/dev/null 2>&1; then
    curl -sLo ~/.dircolors https://raw.github.com/trapd00r/LS_COLORS/master/LS_COLORS || true
  fi
  if [ -f ~/.dircolors ] && command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors ~/.dircolors)" || true
  fi
fi

