#!/bin/zsh
# zsh.sh
# Bash prompt strategy ported to Zsh (native)

# Enable prompt substitution
setopt PROMPT_SUBST

# USER PROMPT SETTINGS (bash.sh uyumlu)
# Host + ☘ + truncated path + prompt char
PS1='%m☘ ${NEW_PWD} %# '
export CLICOLOR=1

# History behavior (bash.sh karşılığı)
HISTSIZE=1000
SAVEHIST=2000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt APPEND_HISTORY

# Compute truncated path before each prompt (bash_prompt_command karşılığı)
__my_shell_zsh_prompt_command() {
  local pwdmaxlen=25
  local trunc_symbol=".."
  local dir="${PWD##*/}"

  if (( ${#dir} > pwdmaxlen )); then
    pwdmaxlen=${#dir}
  fi

  NEW_PWD="${PWD/#$HOME/~}"
  local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))

  if (( pwdoffset > 0 )); then
    NEW_PWD="${NEW_PWD:pwdoffset:pwdmaxlen}"
    NEW_PWD="${trunc_symbol}/${NEW_PWD#*/}"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook -d precmd __my_shell_zsh_prompt_command 2>/dev/null || true
add-zsh-hook precmd __my_shell_zsh_prompt_command
__my_shell_zsh_prompt_command

# Colors (bash.sh’deki sed zincirinin Zsh karşılığı)
PS1='%F{cyan}%m%f☘ %F{green}${NEW_PWD}%f %F{red}%#%f '

# dircolors (GNU ls varsa)
if command ls --version >/dev/null 2>&1; then
  if [ ! -f ~/.dircolors ] && command -v curl >/dev/null 2>&1; then
    curl -sLo ~/.dircolors https://raw.github.com/trapd00r/LS_COLORS/master/LS_COLORS || true
  fi
  if [ -f ~/.dircolors ] && command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors ~/.dircolors)" || true
  fi
fi