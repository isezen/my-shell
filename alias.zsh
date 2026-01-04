#!/bin/zsh
# alias.zsh
# Port of alias.sh for Zsh (best-effort, Zsh-native where it matters)

# ---------------------
# Helpers: command existence
__my_shell_has() { command -v "$1" >/dev/null 2>&1 }

# ---------------------
# Show free memory amount (macOS-oriented, same as alias.sh)
mem () {
  local FREE_BLOCKS INACTIVE_BLOCKS SPECULATIVE_BLOCKS TOTALRAM FREE INACTIVE TOTAL
  FREE_BLOCKS=$(vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')
  INACTIVE_BLOCKS=$(vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')
  SPECULATIVE_BLOCKS=$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
  TOTALRAM=$(system_profiler SPHardwareDataType | grep Memory | awk '{ print $2 $3}')

  FREE=$(((FREE_BLOCKS+SPECULATIVE_BLOCKS)*4096/(1024*1024)))
  INACTIVE=$((INACTIVE_BLOCKS*4096/(1024*1024)))
  TOTAL=$((FREE+INACTIVE))
  TOTAL=$(echo "scale=2; $TOTAL/1024" | bc)
  echo "Free Memory: $TOTAL""GB of $TOTALRAM"
}

cd_aliases () {
  alias cdh='cd ~/'  # Go to Home

  # Examples:
  # ".." or ".1" -> Up 1 level
  # "..." or ".2" -> Up 2 levels
  # "...." or ".3" -> Up 3 levels
  local dotSlash=""
  local dot=".."
  local i
  for i in 1 2 3 4 5; do
    dotSlash="${dotSlash}../"
    local baseName=".${i}"
    alias "${baseName}=cd ${dotSlash}"
    alias "${dot}=cd ${dotSlash}"
    dot="${dot}."
  done
}

ls_aliases () {
  local gnu_ls_suffix="--color --group-directories-first"

  # Listing aliases
  local _ls="ls"
  local _ll="$_ls -l"

  if __my_shell_has ls; then
    local gnuls
    gnuls="$(ls --version 2>/dev/null)" || true
    if [[ -n "$gnuls" ]]; then
      _ls="$_ls $gnu_ls_suffix"
      _ll='ls -lhF --color'
    fi
  fi

  alias dir="$_ls -C -b"
  if __my_shell_has dir; then
    if [[ -n "$(command dir --version 2>/dev/null)" ]]; then
      alias dir="dir $gnu_ls_suffix"
    fi
  fi

  alias vdir="$_ls -l -b"
  if __my_shell_has vdir; then
    if [[ -n "$(command vdir --version 2>/dev/null)" ]]; then
      alias vdir="vdir $gnu_ls_suffix"
    fi
  fi

  if __my_shell_has ll; then
    _ll='ll -hGg --group-directories-first'
    alias vdir="$_ll"
  fi

  # -C=list entries by columns
  alias l="$_ls -CF"
  alias ls="$_ls"
  alias sl='ls'         # Typo correction
  alias la="$_ls -AF"   # List regular + hidden
  alias lh="$_ls -dF .[^.]*"
  alias ld="$_ls -d -- */"
  alias lhd="$_ls -d .[^.]*/"

  # Find Files in current directory
  local _fnd="find . -maxdepth 1 -type"
  local _freg="$_fnd f -a ! -iname \".*\" -print0 | sed -e \"s:./::g\" "
  local _fall="$_fnd f -print0 | sed -e \"s:./::g\""
  local _fhid="$_fnd f -a -iname \".*\" -print0 | sed -e \"s:./::g\""
  local _fadir="$_fnd d \\( -not -iname \\\".\\\" \\) -print0 | sed -e \"s:./::g\""
  local _suf="| xargs -0r $_ls"

  alias lf="$_freg $_suf"   # list regular
  alias laf="$_fall $_suf"  # list regular+hidden
  alias lhf="$_fhid $_suf"  # list hidden
  alias lad="$_fadir | xargs -0r $_ls -dF"

  alias ll="$_ll"
  alias llad="$_fadir | xargs -0r $_ll -d"
  alias llf="$_freg | xargs -0r $_ll -d"
  alias llaf="$_fall | xargs -0r $_ll -d"
  alias llhf="$_fhid | xargs -0r $_ll -d"
  alias lla="$_ll -A"
  alias llh="$_ll -d .[^.]*"

  alias lld="$_ll -dhGg */"
  alias llhd="$_ll -dhGg .[^.]*/"
}

# mkdir a directory and move into that directory
mcd () { mkdir -p "$1" && cd "$1" || return; }

FindFiles () {
  local _searchfile="$1"
  local _search_command="find . -type f \\( -name \"*${_searchfile}*\" \\)"
  eval "$_search_command"
}

dushf () {
  echo "Calculating disk usage of all hidden files in $PWD"
  local _filelist
  _filelist=$(find . -type f -a -iname "*.pdf" -print0 | xargs -r0 command du -ach | sort -h)
  echo "Number of files: $(( $(echo "$_filelist" | wc -l) - 1 ))"
  tail -n 1 <<< "$_filelist"
}

dufiles () {
  local _search_command
  _search_command="find . -type f \\( -name \"*.${1}\" \\) -print0 | xargs -r0 command du -ch | sort -h"
  local _filelist
  _filelist=$(eval "$_search_command")
  echo "$_filelist"
  echo "Number of $1 files: $(( $(echo "$_filelist" | wc -l) - 1 ))"
  tail -n 1 <<< "$_filelist"
}

dusd () {
  local _findAllDirectories
  _findAllDirectories="find . -maxdepth 1 -type d \\( -not -iname \".\" \\) -print0 | sed -e \"s:./::g\""
  local _filelist
  _filelist=$(eval "$_findAllDirectories | xargs -r0 command du -hcd 0 | sed -E \"s:./::\" | sort -h")
  print_files "$_filelist"
  echo "Number of Dirs: $(( $(echo "$_filelist" | wc -l) - 1 ))"
}

print_files () {
  local size line
  local x=0
  while IFS=$'\t' read -r size line; do
    printf "%s\t%s" "$size" "$line"
    [[ -d $line ]] && printf "/"
    echo
    x=$(( x + 1 ))
  done <<< "$1"
}

# ---------------------
# Enable aliases
ls_aliases; unset -f ls_aliases
cd_aliases; unset -f cd_aliases

alias c='clear'
alias sourceme='source ~/.profile'
alias 'rm!=/bin/rm -Rf'
alias fhere='find . -name '

alias topme='top -U $USER'
if __my_shell_has htop; then
  alias top='htop -s PERCENT_CPU'
  alias topme='top -u $USER'
fi

alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias mkdir='mkdir -pv'
alias wget='wget -c'

# Zsh history differs; use fc for consistent output
alias h='fc -l 1'
hs() {
  fc -l 1 |
    awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' |
    grep -v "./" |
    column -c3 -s " " -t |
    sort -nr | nl | head -n10
}
alias hg='fc -l 1 | grep'
alias clhist=': >| ~/.zsh_history; fc -p; exit'

alias j='jobs -l'
alias path='print -l ${(s.:.)PATH}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%Y-%m-%d"'

alias du='du -ahd 1'
alias du.='\du -ahd 0 2> >(grep -v "^du: cannot \(access\|read\)" >&2)'
if __my_shell_has ncdu; then alias du2='ncdu'; fi

alias myip='curl http://ipecho.net/plain; echo'
if __my_shell_has mogrify; then alias webify='mogrify -resize 690\> *.png'; fi

if __my_shell_has grep; then alias grep='grep --color=auto --exclude-dir=\.svn'; fi
if __my_shell_has fgrep; then alias fgrep='fgrep --color=auto'; fi
if __my_shell_has egrep; then alias egrep='egrep --color=auto'; fi
if __my_shell_has dfc; then alias df='dfc'; fi

if __my_shell_has port; then
  alias updateme='sudo port selfupdate && sudo port upgrade outdated'
fi

if __my_shell_has free; then
  alias free='free -mt'
else
  free() {
    vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; \
     /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mb\n", "$1:", \
      $2 * $size / 1048576);'
  }
fi

if __my_shell_has grc; then
  alias ping='grc ping -c 10'
  alias ps='grc ps aux'
else
  alias ping='ping -c 10'
  alias ps='ps aux'
fi

alias ports='netstat -tulanp'

# Distro detection (best-effort)
_distro="unknown"
get_distro() {
  local _myos
  _myos=$(uname)
  if [[ "$_myos" == 'Linux' ]]; then
    _distro=$(lsb_release -si 2>/dev/null || echo unknown)
  elif [[ "$_myos" == 'Darwin' ]]; then
    _distro=$OSTYPE
  fi
}
get_distro

if [[ "$_distro" == 'Ubuntu' ]]; then
  alias sagi='sudo apt-get install'
  alias update='sudo apt-get update && sudo apt-get upgrade'
  alias nginxreload='sudo /usr/sbin/nginx -s reload'
  alias nginxtest='sudo /usr/sbin/nginx -t'
fi

unset -f __my_shell_has
unset -f get_distro
unset _distro