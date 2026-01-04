#!/bin/zsh
# zsh prompt support
# Bash prompt strategy ported to Zsh (native)

# Enable prompt substitution
setopt PROMPT_SUBST

# USER PROMPT SETTINGS (bash.sh compatible)
# Host + ☘ + truncated path + prompt char
PS1='%m☘ ${NEW_PWD} [%#] '

# Compute truncated path before each prompt (bash_prompt_command equivalent)
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

# Colors (bash.sh color chain Zsh equivalent)
PS1='%F{cyan}%m%f☘ %F{green}${NEW_PWD}%f [%F{red}%#%f] '

