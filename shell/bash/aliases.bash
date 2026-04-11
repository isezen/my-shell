#!/usr/bin/env bash
# 2016-03-28
# sezenismail@gmail.com
# Bash aliases and utility functions (best-effort port from fish)

# ============================================================================
# Helper Functions & System Detection
# ============================================================================

__my_shell_has() {
  # Check command existence
  [[ $# -ge 1 ]] || return 1
  command -v -- "$1" >/dev/null 2>&1
}

__get_os() { uname; }
_myos="$(__get_os)"

# ============================================================================
# Terminal & Display
# ============================================================================

# Clear terminal
if __my_shell_has clear; then
  # clear terminal
  c() { command clear; }
fi

# ============================================================================
# Directory Navigation
# ============================================================================
# Go to Home
cdh() { cd ~/"$1" 2>/dev/null || cd ~ || return; echo "You are at $HOME"; }
# Up 1 level
..() { cd ../"$1" 2>/dev/null || cd ..; }
# Up 2 levels
...() { cd ../../"$1" 2>/dev/null || cd ../..; }
# Up 3 levels
....() { cd ../../../"$1" 2>/dev/null || cd ../../..; }
# Up 4 levels
.....() { cd ../../../../"$1" 2>/dev/null || cd ../../../..; }
# Up 5 levels
......() { cd ../../../../../"$1" 2>/dev/null || cd ../../../../..; }

# shellcheck disable=SC2288
# Up 1 level
.1() { .. "$@"; }
# shellcheck disable=SC2288
# Up 2 levels
.2() { ... "$@"; }
# shellcheck disable=SC2288
# Up 3 levels
.3() { .... "$@"; }
# shellcheck disable=SC2288
# Up 4 levels
.4() { ..... "$@"; }
# shellcheck disable=SC2288
# Up 5 levels
.5() { ...... "$@"; }

# ============================================================================
# File Listing
# ============================================================================

# ls wrapper (keeps original behavior, best-effort)
if __my_shell_has ls && __my_shell_has getopt; then
  # list files
  ls() {
    local param=()

    # GNU ls niceties
    if command ls --version >/dev/null 2>&1; then
      param+=(--color --group-directories-first)
    fi

    # Detect "ls -l" using getopt (best-effort parity with original)
    local args
    args="$(getopt -s sh -l '' -o l -- "$@" 2>/dev/null)" || args=""
    if [[ "$args" == " -l --"* ]]; then
      if command -v ll >/dev/null 2>&1; then
        command ll -hGg "${param[@]}" "$@"
      else
        command ls "${param[@]}" "$@"
      fi
    else
      command ls "${param[@]}" "$@"
    fi
  }
fi

# ll wrapper
if __my_shell_has ll; then
  # long list
  ll() { command ll -hGg --group-directories-first "$@"; }
else
  # long list
  ll() { command ls -lh "$@"; }
fi

if __my_shell_has dir; then
  # list entries by columns
  dir() {
    local param=()
    if command dir --version >/dev/null 2>&1; then
      param+=(--color --group-directories-first)
      if [[ -t 1 ]]; then
        param+=(--indicator-style=classify)
      fi
    fi
    command dir "${param[@]}" "$@"
  }
else
  # list entries by columns
  dir() { command ls -C -b "$@"; }
fi

# Prefer external "ll" if available; else prefer "vdir" if available; else fallback
if __my_shell_has ll; then
  # vertical directory listing
  vdir() { command ll -hGg "$@"; }
elif __my_shell_has vdir; then
  # vertical directory listing
  vdir() {
    local param=()
    if command dir --version >/dev/null 2>&1; then
      param+=(--color --group-directories-first)
    fi
    command vdir "${param[@]}" "$@"
  }
else
  # vertical directory listing
  vdir() { command ls -l -b "$@"; }
fi

# Basic listing aliases
# jobs list
j() { jobs -l "$@"; }
# list entries by columns
l() { ls -CF "$@"; }
# list regular + hidden
la() { ls -AF "$@"; }
# typo correction for ls
sl() { ls "$@"; }
# list regular+hidden files
laf() {
  local param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  find . -maxdepth 1 -type f -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'ls "$@"' _ "${param[@]}" "$@"
}
# list regular directories
ld() { ls -d -- * "$@"; }
# list regular files
lf() {
  local param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  find . -maxdepth 1 -type f ! -iname '.*' -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'ls "$@"' _ "${param[@]}" "$@"
}
# list hidden items
lh() { ls -Ad .* "$@"; }
# list hidden directories
lhd() { ls -d .*/ "$@"; }
# list hidden files
lhf() {
  local param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  find . -maxdepth 1 -type f -iname '.*' -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'ls "$@"' _ "${param[@]}" "$@"
}
# list all directories
lad() {
  local param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  find . -maxdepth 1 -type d ! -iname '.' -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'ls -dF "$@"' _ "${param[@]}" "$@"
}
# long list all
lla() { ll -A "$@"; }
# long list regular directories
lld() { ll -dhGg -- */ "$@"; }
# long list hidden
llh() { ll -hGgAd -- .* "$@"; }
# long list hidden directories
llhd() { ll -dhGg -- .*/ "$@"; }
# long list regular files
llf()  { find . -maxdepth 1 -type f ! -iname '.*' -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'll -hGd "$@"' _ "$@"; }
# long list all directories
llad() { find . -maxdepth 1 -type d ! -iname '.'   -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'll -hGd "$@"' _ "$@"; }
# long list all files + hidden
llaf() { find . -maxdepth 1 -type f               -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'll -hGd "$@"' _ "$@"; }
# long list only hidden files
llhf() { find . -maxdepth 1 -type f -iname '.*'   -print0 | sed -e 's:^\./::g' | xargs -0 -r sh -c 'll -hGgd "$@"' _ "$@"; }

# ============================================================================
# File Operations & Search
# ============================================================================
# find files by name pattern
FindFiles() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: FindFiles <pattern>" >&2
    return 1
  fi
  local searchfile="$1"
  command find . -type f -name "*${searchfile}*"
}
# find in current directory
fhere() { command find . -name "$@"; }

# ============================================================================
# Disk Usage
# ============================================================================

if __my_shell_has du; then
  if command du --version >/dev/null 2>&1; then
    # disk usage
    du()  { command du -k -d 1 -- "$@" 2>/dev/null; }
      # disk usage current directory
    du.() { command du -k -d 0 -- "$@" 2>/dev/null; }
  else
    # disk usage
    du()  { command du -k -d 1 "$@" 2>/dev/null; }
      # disk usage current directory
    du.() { command du -k -d 0 "$@" 2>/dev/null; }
  fi

  if __my_shell_has ncdu; then
    # interactive disk usage
    du2() { command ncdu "$@"; }
  fi
else
  if __my_shell_has ncdu; then
    # disk usage
    du() { command ncdu "$@"; }
  fi
fi

if __my_shell_has du && __my_shell_has find && __my_shell_has awk; then
  # disk usage of hidden files
  dushf() {
    echo "Calculating disk usage of hidden files in $PWD"
    find . -path './.git' -prune -o -type f -name '.*' -print0 |
      while IFS= read -r -d '' f; do
        command du -k "$f"
      done |
      awk '
        { sum += $1; count++ }
        END {
          printf "Hidden files: %d\n", count
          printf "Total: %d KB (~%.2f MB)\n", sum, sum/1024
        }
      '
  }
fi

if __my_shell_has du && __my_shell_has mktemp && __my_shell_has sort && __my_shell_has wc && \
   __my_shell_has awk && __my_shell_has find && __my_shell_has tr; then
  # disk usage of files by extension
  dufiles() {
    local ext="${1:-}"
    if [[ -z "$ext" ]]; then
      echo "Usage: dufiles <ext>" >&2
      return 2
    fi
    ext="${ext#.}"

    local tmp
    tmp="$(mktemp)" || { echo "mktemp failed" >&2; return 1; }

    find . -type f -name "*.${ext}" -print0 |
      while IFS= read -r -d '' f; do
        command du -k "$f"
      done > "$tmp"

    sort -n "$tmp"
    echo

    local count
    count="$(wc -l < "$tmp" | tr -d ' ')"
    echo "Number of ${ext} files: $count"

    local total_kb total_mb
    total_kb="$(awk '{s+=$1} END{print s+0}' "$tmp")"
    total_mb="$(awk -v s="$total_kb" 'BEGIN{printf "%.2f", s/1024}' </dev/null)"
    echo "Total: ${total_kb} KB (~${total_mb} MB)"

    rm -f -- "$tmp"
  }
  # disk usage of directories
  dusd() {
    local tmp
    tmp="$(mktemp)" || { echo "mktemp failed" >&2; return 1; }

    find . -maxdepth 1 -mindepth 1 -type d -print0 |
      while IFS= read -r -d '' d; do
        local name kb
        name="${d#./}"
        kb="$(command du -sk -- "$d" 2>/dev/null | awk '{print $1}')"
        printf "%s\t%s/\n" "$kb" "$name"
      done > "$tmp"

    if [[ -s "$tmp" ]]; then
      sort -n "$tmp"
      local count
      count="$(wc -l < "$tmp" | tr -d ' ')"
      echo "Number of Dirs: $count"
    else
      echo "Number of Dirs: 0"
    fi

    rm -f -- "$tmp"
  }
fi

# df wrapper
if __my_shell_has dfc; then
  # dfc if available
  df() { command dfc "$@"; }
else
  # dfc if available
  df() { command df "$@"; }
fi

# ============================================================================
# Text Processing & Search
# ============================================================================

if __my_shell_has grep; then
  # colorize grep
  grep() { command grep --color=auto "$@"; }
fi
if __my_shell_has fgrep; then
  # colorize fgrep
  fgrep() { command fgrep --color=auto "$@"; }
elif __my_shell_has grep; then
  # colorize fgrep
  fgrep() { command grep -F --color=auto "$@"; }
fi
if __my_shell_has egrep; then
  # colorize egrep
  egrep() { command egrep --color=auto "$@"; }
elif __my_shell_has grep; then
  # colorize egrep
  egrep() { command grep -E --color=auto "$@"; }
fi

if __my_shell_has ccze; then
  # head with column width
  head() {
    local x
    x="$(tput cols 2>/dev/null || echo 80)"
    x=$((x - 1))
    local cmd="command head \"\$@\" | command cut -b \"1-$x\""
    cmd="$cmd | command ccze -A"
    eval "$cmd"
  }
  # tail with column width
  tail() {
    local x
    x="$(tput cols 2>/dev/null || echo 80)"
    x=$((x - 1))
    local cmd="command tail \"\$@\" | command cut -b \"1-$x\""
    cmd="$cmd | command ccze -A"
    eval "$cmd"
  }
elif __my_shell_has grc; then
  # head with column width
  head() {
    local x
    x="$(tput cols 2>/dev/null || echo 80)"
    x=$((x - 1))
    local cmd="command head \"\$@\" | command cut -b \"1-$x\""
    cmd="grc $cmd"
    eval "$cmd"
  }
  # tail with column width
  tail() {
    local x
    x="$(tput cols 2>/dev/null || echo 80)"
    x=$((x - 1))
    local cmd="command tail \"\$@\" | command cut -b \"1-$x\""
    cmd="grc $cmd"
    eval "$cmd"
  }
fi

# ============================================================================
# History
# ============================================================================
# history
h()  { history "$@"; }
# history clear
hc() { history -c; }
if __my_shell_has grep; then
  # search history
  hg() { history | command grep "$@"; }
fi
# clear history
clhist() { history -c; exit; }
# statistics of history
hs() {
  # Top 10 commands by frequency (best-effort)
  command history | awk '{CMD[$2]++;count++;} END { for (a in CMD) print CMD[a] " " CMD[a]/count*100 "% " a; }' |
    command grep -v "./" |
    command column -c3 -s " " -t |
    command sort -nr |
    command nl |
    command head -n10
}

# ============================================================================
# System Information
# ============================================================================

# macOS memory helper (vm_stat/system_profiler)
if __my_shell_has vm_stat && __my_shell_has system_profiler && __my_shell_has grep && \
   __my_shell_has awk && __my_shell_has sed; then
  # show free memory amount
  mem() {
    local FREE_BLOCKS INACTIVE_BLOCKS SPECULATIVE_BLOCKS TOTALRAM FREE INACTIVE TOTAL
    FREE_BLOCKS="$(vm_stat | grep free | awk '{print $3}' | sed 's/\.//')"
    INACTIVE_BLOCKS="$(vm_stat | grep inactive | awk '{print $3}' | sed 's/\.//')"
    SPECULATIVE_BLOCKS="$(vm_stat | grep speculative | awk '{print $3}' | sed 's/\.//')"
    TOTALRAM="$(system_profiler SPHardwareDataType | grep Memory | awk '{print $2 $3}')"

    FREE=$(( (FREE_BLOCKS + SPECULATIVE_BLOCKS) * 4096 / (1024*1024) ))
    INACTIVE=$(( INACTIVE_BLOCKS * 4096 / (1024*1024) ))

    if command -v bc >/dev/null 2>&1; then
      TOTAL="$(echo "scale=2; ($FREE+$INACTIVE)/1024" | bc)"
    else
      TOTAL="$(( (FREE + INACTIVE) / 1024 ))"
    fi

    echo "Free Memory: ${TOTAL}GB of ${TOTALRAM}"
  }
fi

# Define free only if dependencies exist (best-effort parity)
if __my_shell_has free; then
  # free memory
  free() { command free -mt "$@"; }
elif [[ "$_myos" == "Darwin" ]] && __my_shell_has vm_stat && __my_shell_has perl; then
  # free memory
  free() {
    command vm_stat | perl -ne '
      /page size of (\d+)/ and $size=$1;
      /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mb\n", "$1:", $2 * $size / 1048576);
    ' "$@"
  }
fi

# macOS internal IP (en0)
if __my_shell_has ifconfig && __my_shell_has grep && __my_shell_has cut; then
  # show internal ip
  internalip() {
    ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2
  }
fi

# Public IP helper
if __my_shell_has curl; then
  # show my ip
  myip() { command curl -fsS https://api.ipify.org; echo; }
elif __my_shell_has wget; then
  # show my ip
  myip() { command wget -qO- https://api.ipify.org; echo; }
elif __my_shell_has fetch; then
  # show my ip
  myip() { command fetch -qo - https://api.ipify.org; echo; }
fi
# current time
now()     { date +"%Y-%m-%d %T"; }
# current time
nowtime() { date +"%T"; }
# current date
nowdate() { date +"%Y-%m-%d"; }
# show PATH
showpath() { printf "%s\n" "$PATH"; }

# ============================================================================
# Process Management
# ============================================================================

if __my_shell_has grc; then
  # ping with count
  ping() { command grc ping -c 10 "$@"; }
  # process status
  ps()   { command grc ps aux "$@"; }
else
  # ping with count
  ping() { command ping -c 10 "$@"; }
  # process status
  ps()   { command ps aux "$@"; }
fi
# searchable process table
psg() { command ps aux | command grep -v grep | command grep -i -e VSZ -e "$@"; }
# find process
pfind() {
  command ps aux | grep "$*" | command head -1 | cut -d " " -f 5
}

if __my_shell_has htop; then
  #
  top()   { command htop -s PERCENT_CPU "$@"; }
  # top for current user
  topme() { command htop -u "$USER" "$@"; }
fi

# ports (define only if tools exist; best-effort parity)
if [[ "$_myos" == "Linux" ]]; then
  if __my_shell_has ss; then
    # netstat
    ports() { command ss -tulpn "$@"; }
  elif __my_shell_has netstat; then
    # netstat
    ports() { command netstat -tulanp "$@"; }
  fi
elif [[ "$_myos" == "Darwin" ]]; then
  if __my_shell_has lsof; then
    # netstat
    ports() { command lsof -nP -iTCP -sTCP:LISTEN "$@"; }
  elif __my_shell_has netstat; then
    # netstat
    ports() { command netstat -anv -p tcp "$@"; }
  fi
fi

# ============================================================================
# Network
# ============================================================================

if __my_shell_has wget; then
  # continue download in case of interruption
  wget() { command wget -c "$@"; }
fi

# ============================================================================
# File Management
# ============================================================================
# mkdir a directory and move into that directory
mcd() { command mkdir -p "$1" && command cd "$1" || return; }
# mkdir with parent directories and verbose output
mkd() { command mkdir -pv "$@" && command cd "$1" || return; }
# mkdir with parent directories
mkdir() { command mkdir -p "$@"; }
function rm! { command rm -rf -- "$@"; }

# ============================================================================
# Package Management
# ============================================================================

if [[ "$_myos" == "Linux" ]]; then
  if __my_shell_has apt-get; then
    # sudo apt-get install
    sagi() { sudo apt-get install "$@"; }
    # update Linux/macports
    update() { sudo apt-get update && sudo apt-get upgrade; }
  else
    # update Linux/macports
    update() { echo "install apt-get" >&2; return 127; }
  fi
elif [[ "$_myos" == "Darwin" ]]; then
  if __my_shell_has port; then
    # update Linux/macports
    update() { sudo port selfupdate && sudo port upgrade outdated "$@"; }
  else
    if __my_shell_has brew; then
      # update Linux/macports
      update() { brew update; }
    else
      # update Linux/macports
      update() { echo "install MacPorts or Homebrew" >&2; return 127; }
    fi
  fi
else
  # update Linux/macports
  update() { echo "unsupported system (${_myos})" >&2; return 1; }
fi

# ============================================================================
# Web Server
# ============================================================================

if __my_shell_has nginx; then
  # test nginx config
  nginxtest()  { sudo nginx -t "$@"; }
  # reload nginx
  nginxreload(){ sudo nginx -s reload "$@"; }
fi

# ============================================================================
# Image Processing
# ============================================================================

if __my_shell_has mogrify; then
  # resize images for web
  webify() { command mogrify -resize '690>' -- *.png "$@"; }
fi

# ============================================================================
# Specialized Tools
# ============================================================================

if __my_shell_has radian; then
  # radian
  r() { command radian "$@"; }
fi
# source profile/config
sourceme() {
  if [ -f ~/.bashrc ]; then
    # shellcheck disable=SC1090
    source ~/.bashrc
  elif [ -f ~/.bash_profile ]; then
    # shellcheck disable=SC1090
    source ~/.bash_profile
  elif [ -f ~/.profile ]; then
    # shellcheck disable=SC1090
    source ~/.profile
  else
    echo "no bash config found" >&2
    return 1
  fi
}

# ============================================================================
# Cleanup
# ============================================================================

unset -f __my_shell_has __get_os
unset _myos
