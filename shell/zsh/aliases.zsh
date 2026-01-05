#!/usr/bin/env zsh
# 2016-03-28
# sezenismail@gmail.com
# Zsh aliases and utility functions (best-effort port from fish)

# ============================================================================
# Helper Functions & System Detection
# ============================================================================

__my_shell_has() {
  # Check command existence
  (( $# >= 1 )) || return 1
  command -v -- "$1" >/dev/null 2>&1
}

__get_os() { uname; }
_myos="$(__get_os)"

# ============================================================================
# Terminal & Display
# ============================================================================

# Clear terminal
if __my_shell_has clear; then
  c() { command clear; }
fi

# Greeting (only define if fortune exists)
if __my_shell_has fortune; then
  fish_greeting() {
    # Colorized fortune (best-effort)
    local -a cols
    cols=(red green brown yellow blue magenta purple cyan white)
    local i=$(( (RANDOM % 9) + 1 ))

    if __my_shell_has tput; then
      # Map to ANSI colors (best-effort; may vary by terminfo)
      # Use setaf with a simple numeric palette
      tput setaf $(( (RANDOM % 7) + 1 )) 2>/dev/null || true
    fi

    fortune -a
    echo

    if __my_shell_has tput; then
      tput sgr0 2>/dev/null || true
    fi
  }
fi

# ============================================================================
# Directory Navigation
# ============================================================================

cdh() { cd ~/"$1" 2>/dev/null || cd ~ || return; echo "You are at $HOME"; }

..() { builtin cd .. "${@}"; }
...() { builtin cd ../.. "${@}"; }
....() { builtin cd ../../.. "${@}"; }
.....() { builtin cd ../../../.. "${@}"; }
......() { builtin cd ../../../../.. "${@}"; }

.1() { .. "$@"; }
.2() { ... "$@"; }
.3() { .... "$@"; }
.4() { ..... "$@"; }
.5() { ...... "$@"; }

# ============================================================================
# File Listing
# ============================================================================

# ls wrapper (keeps original behavior, best-effort)
if __my_shell_has ls && __my_shell_has getopt; then
  ls() {
    local -a param
    param=()

    # GNU ls niceties
    if command ls --version >/dev/null 2>&1; then
      param+=(--color --group-directories-first)
    fi

    # Detect "ls -l" using getopt (best-effort parity with original fish)
    local args
    args="$(getopt -s sh -l '' -o l -- "$@" 2>/dev/null)" || args=""
    if [[ "$args" == " -l --"* ]]; then
      if __my_shell_has ll; then
        command ll -hGg "${param[@]}" "$@"
      else
        command ls "${param[@]}" "$@"
      fi
    else
      command ls "${param[@]}" "$@"
    fi
  }
fi

# ll wrapper: if an external ll exists, prefer it; else fallback to ls -lh
if __my_shell_has ll; then
  ll() { command ll -hGg --group-directories-first "$@"; }
else
  ll() { command ls -lh "$@"; }
fi

if __my_shell_has dir; then
  dir() {
    local -a param
    param=()

    # If this is GNU dir (supports --version), enable GNU-only niceties
    if command dir --version >/dev/null 2>&1; then
      param+=(--color --group-directories-first)
      if [[ -t 1 ]]; then
        param+=(--indicator-style=classify)
      fi
    fi

    command dir "${param[@]}" "$@"
  }
else
  dir() { command ls -C -b "$@"; }
fi

# Prefer external "ll" if available; else prefer "vdir" if available; else fallback
if __my_shell_has ll; then
  vdir() { command ll -hGg "$@"; }
elif __my_shell_has vdir; then
  vdir() {
    local -a param
    param=()
    if command dir --version >/dev/null 2>&1; then
      param+=(--color --group-directories-first)
    fi
    command vdir "${param[@]}" "$@"
  }
else
  vdir() { command ls -l -b "$@"; }
fi

# Basic listing aliases
j() { jobs -l "$@"; }
l() { ls -CF "$@"; }
la() { ls -AF "$@"; }
sl() { ls "$@"; }

# Advanced listing functions
laf() {
  local -a param
  param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  command find . -maxdepth 1 -type f -print0 | sed -e 's:^\./::g' | xargs -0 -r ls "${param[@]}" "$@"
}

ld() { ls -d -- * "$@"; }

lf() {
  local -a param
  param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  command find . -maxdepth 1 -type f ! -iname '.*' -print0 | sed -e 's:^\./::g' | xargs -0 -r ls "${param[@]}" "$@"
}

lh()  { ls -Ad .* "$@"; }
lhd() { ls -d .*/ "$@"; }

lhf() {
  local -a param
  param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  command find . -maxdepth 1 -type f -iname '.*' -print0 | sed -e 's:^\./::g' | xargs -0 -r ls "${param[@]}" "$@"
}

lad() {
  local -a param
  param=()
  if command ls --version >/dev/null 2>&1; then
    param+=(--color --group-directories-first)
  fi
  command find . -maxdepth 1 -type d ! -iname '.' -print0 | sed -e 's:^\./::g' | xargs -0 -r ls -dF "${param[@]}" "$@"
}

# Long listing functions
lla() { ll -A "$@"; }
lld() { ll -dhGg */ "$@"; }
llh() { ll -hGgAd .* "$@"; }
llhd() { ll -dhGg .*/ "$@"; }

llf()  { command find . -maxdepth 1 -type f ! -iname '.*' -print0 | sed -e 's:^\./::g' | xargs -0 -r ll -hGd "$@"; }
llad() { command find . -maxdepth 1 -type d ! -iname '.'   -print0 | sed -e 's:^\./::g' | xargs -0 -r ll -hGd "$@"; }
llaf() { command find . -maxdepth 1 -type f               -print0 | sed -e 's:^\./::g' | xargs -0 -r ll -hGd "$@"; }
llhf() { command find . -maxdepth 1 -type f -iname '.*'   -print0 | sed -e 's:^\./::g' | xargs -0 -r ll -hGgd "$@"; }

# ============================================================================
# File Operations & Search
# ============================================================================

FindFiles() {
  if (( $# == 0 )); then
    echo "Usage: FindFiles <pattern>" >&2
    return 1
  fi
  local searchfile="$1"
  command find . -type f -name "*${searchfile}*"
}

fhere() { command find . -name "$@"; }

# ============================================================================
# Disk Usage
# ============================================================================

if __my_shell_has du; then
  if command du --version >/dev/null 2>&1; then
    # GNU du
    du()  { command du -k -d 1 -- "$@" 2>/dev/null; }
    du.() { command du -k -d 0 -- "$@" 2>/dev/null; }
  else
    # BSD du (macOS)
    du()  { command du -k -d 1 "$@" 2>/dev/null; }
    du.() { command du -k -d 0 "$@" 2>/dev/null; }
  fi

  if __my_shell_has ncdu; then
    du2() { command ncdu "$@"; }
  fi
else
  if __my_shell_has ncdu; then
    du() { command ncdu "$@"; }
  fi
fi

if __my_shell_has du && __my_shell_has find && __my_shell_has awk; then
  dushf() {
    echo "Calculating disk usage of hidden files in $PWD"
    command find . -path './.git' -prune -o -type f -name '.*' -print0 |
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

  dufiles() {
    local ext="${1:-}"
    if [[ -z "$ext" ]]; then
      echo "Usage: dufiles <ext>" >&2
      return 2
    fi
    ext="${ext#.}"

    local tmp
    tmp="$(mktemp)" || { echo "mktemp failed" >&2; return 1; }

    command find . -type f -name "*.${ext}" -print0 |
      while IFS= read -r -d '' f; do
        command du -k "$f"
      done > "$tmp"

    command sort -n "$tmp"
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

  dusd() {
    local tmp
    tmp="$(mktemp)" || { echo "mktemp failed" >&2; return 1; }

    command find . -maxdepth 1 -mindepth 1 -type d -print0 |
      while IFS= read -r -d '' d; do
        local name kb
        name="${d#./}"
        kb="$(command du -sk -- "$d" 2>/dev/null | awk '{print $1}')"
        printf "%s\t%s/\n" "$kb" "$name"
      done > "$tmp"

    if [[ -s "$tmp" ]]; then
      command sort -n "$tmp"
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
  df() { command dfc "$@"; }
else
  df() { command df "$@"; }
fi

# ============================================================================
# Text Processing & Search
# ============================================================================

if __my_shell_has grep; then
  grep() { command grep --color=auto "$@"; }
fi
if __my_shell_has fgrep; then
  fgrep() { command fgrep --color=auto "$@"; }
elif __my_shell_has grep; then
  fgrep() { command grep -F --color=auto "$@"; }
fi
if __my_shell_has egrep; then
  egrep() { command egrep --color=auto "$@"; }
elif __my_shell_has grep; then
  egrep() { command grep -E --color=auto "$@"; }
fi

head() {
  local x
  x="$(tput cols 2>/dev/null || echo 80)"
  x=$((x - 1))
  if __my_shell_has ccze; then
    command head "$@" | command cut -b "1-$x" | command ccze -A
  elif __my_shell_has grc; then
    grc command head "$@" | command cut -b "1-$x"
  else
    command head "$@" | command cut -b "1-$x"
  fi
}

tail() {
  local x
  x="$(tput cols 2>/dev/null || echo 80)"
  x=$((x - 1))
  if __my_shell_has ccze; then
    command tail "$@" | command cut -b "1-$x" | command ccze -A
  elif __my_shell_has grc; then
    grc command tail "$@" | command cut -b "1-$x"
  else
    command tail "$@" | command cut -b "1-$x"
  fi
}

# ============================================================================
# History
# ============================================================================

h() { history "$@"; }

# Zsh cannot "history --clear" like fish; emulate with fc builtin.
hc() {
  # Clear in-memory history (best-effort)
  fc -p
  : >| "${HISTFILE:-$HOME/.zsh_history}" 2>/dev/null || true
  fc -R "${HISTFILE:-$HOME/.zsh_history}" 2>/dev/null || true
}

if __my_shell_has grep; then
  hg() { fc -l 1 | command grep "$@"; }
fi

clhist() { hc; exit; }

hs() {
  fc -l 1 | awk '{CMD[$2]++;count++;} END { for (a in CMD) print CMD[a] " " CMD[a]/count*100 "% " a; }' |
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
mem() {
  __my_shell_has vm_stat || { echo "mem: vm_stat not found" >&2; return 127; }
  __my_shell_has system_profiler || { echo "mem: system_profiler not found" >&2; return 127; }

  local FREE_BLOCKS INACTIVE_BLOCKS SPECULATIVE_BLOCKS TOTALRAM FREE INACTIVE TOTAL
  FREE_BLOCKS="$(vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')"
  INACTIVE_BLOCKS="$(vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')"
  SPECULATIVE_BLOCKS="$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')"
  TOTALRAM="$(system_profiler SPHardwareDataType | grep Memory | awk '{ print $2 $3}')"

  FREE=$(( (FREE_BLOCKS + SPECULATIVE_BLOCKS) * 4096 / (1024*1024) ))
  INACTIVE=$(( INACTIVE_BLOCKS * 4096 / (1024*1024) ))

  if __my_shell_has bc; then
    TOTAL="$(echo "scale=2; ($FREE+$INACTIVE)/1024" | bc)"
  else
    TOTAL="$(( (FREE + INACTIVE) / 1024 ))"
  fi

  echo "Free Memory: ${TOTAL}GB of ${TOTALRAM}"
}

# Define free only if dependencies exist (per your preference)
if __my_shell_has free; then
  free() { command free -mt "$@"; }
elif [[ "$_myos" == "Darwin" ]] && __my_shell_has vm_stat && __my_shell_has perl; then
  free() {
    command vm_stat | perl -ne '
      /page size of (\d+)/ and $size=$1;
      /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mb\n", "$1:", $2 * $size / 1048576);
    ' "$@"
  }
fi

# macOS internal IP (en0)
if __my_shell_has ifconfig && __my_shell_has grep && __my_shell_has cut; then
  internalip() {
    ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2
  }
fi

# Public IP helper (curl preferred; fallbacks)
if __my_shell_has curl; then
  myip() { command curl -fsS https://api.ipify.org; echo; }
elif __my_shell_has wget; then
  myip() { command wget -qO- https://api.ipify.org; echo; }
elif __my_shell_has fetch; then
  myip() { command fetch -qo - https://api.ipify.org; echo; }
fi

now()     { date +"%Y-%m-%d %T"; }
nowtime() { date +"%T"; }
nowdate() { date +"%Y-%m-%d"; }

showpath() { printf "%s\n" "$PATH"; }

# ============================================================================
# Process Management
# ============================================================================

if __my_shell_has grc; then
  ping() { command grc ping -c 10 "$@"; }
  ps()   { command grc ps aux "$@"; }
else
  ping() { command ping -c 10 "$@"; }
  ps()   { command ps aux "$@"; }
fi

psg() { command ps aux | command grep -v grep | command grep -i -e VSZ -e "$@"; }

pfind() {
  command ps aux | grep "$*" | command head -1 | cut -d " " -f 5
}

if __my_shell_has htop; then
  top()   { command htop -s PERCENT_CPU "$@"; }
  topme() { command htop -u "$USER" "$@"; }
fi

# ports (define only if tools exist; per your preference)
if [[ "$_myos" == "Linux" ]]; then
  if __my_shell_has ss; then
    ports() { command ss -tulpn "$@"; }
  elif __my_shell_has netstat; then
    ports() { command netstat -tulanp "$@"; }
  fi
elif [[ "$_myos" == "Darwin" ]]; then
  if __my_shell_has lsof; then
    ports() { command lsof -nP -iTCP -sTCP:LISTEN "$@"; }
  elif __my_shell_has netstat; then
    ports() { command netstat -anv -p tcp "$@"; }
  fi
fi

# ============================================================================
# Network
# ============================================================================

if __my_shell_has wget; then
  wget() { command wget -c "$@"; }
fi

# ============================================================================
# File Management
# ============================================================================

mcd() { command mkdir -p "$1" && builtin cd "$1" || return; }
mkd() { command mkdir -pv "$@" && builtin cd "$1" || return; }
mkdir() { command mkdir -p "$@"; }

rm!() { command rm -rf -- "$@"; }

# ============================================================================
# Package Management
# ============================================================================

# Update function definition based on system
if [[ "$_myos" == "Linux" ]]; then
  if __my_shell_has apt-get; then
    sagi() { command sudo apt-get install "$@"; }
    update() { command sudo apt-get update && command sudo apt-get upgrade; }
  else
    update() { echo "install apt-get" >&2; return 127; }
  fi
elif [[ "$_myos" == "Darwin" ]]; then
  if __my_shell_has port; then
    update() { command sudo port selfupdate && command sudo port upgrade outdated "$@"; }
  else
    if __my_shell_has brew; then
      update() { command brew update; }
    else
      update() { echo "install MacPorts or Homebrew" >&2; return 127; }
    fi
  fi
else
  update() { echo "unsupported system (${_myos})" >&2; return 1; }
fi

# ============================================================================
# Web Server
# ============================================================================

if __my_shell_has nginx; then
  nginxtest() { command sudo nginx -t "$@"; }
  nginxreload() { command sudo nginx -s reload "$@"; }
fi

# ============================================================================
# Image Processing
# ============================================================================

if __my_shell_has mogrify; then
  webify() { command mogrify -resize '690>' *.png "$@"; }
fi

# ============================================================================
# Specialized Tools
# ============================================================================

if __my_shell_has radian; then
  r() { command radian "$@"; }
fi

sourceme() {
  if [ -f ~/.zshrc ]; then
    source ~/.zshrc
  elif [ -f ~/.zprofile ]; then
    source ~/.zprofile
  elif [ -f ~/.zlogin ]; then
    source ~/.zlogin
  else
    echo "no zsh config found" >&2
    return 1
  fi
}

# ============================================================================
# Cleanup
# ============================================================================

unset -f __my_shell_has __get_os
unset _myos