#!/bin/bash
# 2016-03-27
# sezenismail@gmail.com
# Shiny bash promt support and dircolors support
#


# USER PROMT SETTINGS
# Date: \D{%y-%m-%d}
# Time: \t
# User: \u
# Host: \h
# Path: \${NEW_PWD}
# Base prompt template. Keep bash prompt escapes literal.
# Use single quotes so `${NEW_PWD}` is expanded at *prompt render* time (after PROMPT_COMMAND updates it).
PS1='\h ☘ ${NEW_PWD} [\$] '
export CLICOLOR=1

# append to the history file, don't overwrite it
shopt -s histappend
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000
# don't put duplicate lines or lines starting with space in the history.
export HISTCONTROL=ignoreboth

bash_prompt_command() {
  local pwdmaxlen=25
  local trunc_symbol=".."
  local dir=${PWD##*/}
  pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
  NEW_PWD=${PWD/#$HOME/\~}
  local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
  if [ ${pwdoffset} -gt "0" ];then
    NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
    NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
  fi
}

bash_prompt() {
  if test -t 1; then
    ncolors=$(tput colors 2>/dev/null)
    if test -n "$ncolors" && test "$ncolors" -ge 8; then
      # Build a colored PS1 that matches fish/zsh intent:
      # - username (\u) cyan (non-bold)
      # - path green (non-bold)
      # - prompt char red
      # Use bash \[...\] markers so readline calculates width correctly.
      PS1='\[\033[0;36m\]\u\[\033[0m\] ☘ \[\033[0;32m\]${NEW_PWD}\[\033[0m\] \[\033[0;31m\][\$]\[\033[0m\] '
    fi
  fi
}

PROMPT_COMMAND=bash_prompt_command
bash_prompt
unset bash_prompt

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
