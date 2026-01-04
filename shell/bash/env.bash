#!/bin/bash
# 2016-03-27
# sezenismail@gmail.com
# Bash environment settings (history, dircolors, etc.)
#

export CLICOLOR=1

# append to the history file, don't overwrite it
shopt -s histappend
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
# don't put duplicate lines or lines starting with space in the history.
export HISTCONTROL=ignoreboth

# Set dircolors (GNU ls)
gnuls="$(ls --version 2>/dev/null)" || true
if [ -n "$gnuls" ];then
  # Set dircolors
  if [ ! -f ~/.dircolors ]; then
    if command -v curl >/dev/null 2>&1; then
      curl -sLo ~/.dircolors https://raw.github.com/trapd00r/LS_COLORS/master/LS_COLORS || true
    fi
  fi
  if [ -f ~/.dircolors ] && command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b ~/.dircolors)" || true
  fi
fi

unset gnuls

