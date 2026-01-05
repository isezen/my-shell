#!/usr/bin/env fish
# 2016-03-28
# sezenismail@gmail.com
# Fish aliases and utility functions

# ============================================================================
# Helper Functions & System Detection
# ============================================================================

# ---------------------
# Helpers: command existence
function __my_shell_has
    if test (count $argv) -lt 1
        return 1
    end
    type -q -- $argv[1]
end

# Get OS
function __get_os; uname; end
set -g _myos (__get_os)

# ---------------------

# ============================================================================
# Terminal & Display
# ============================================================================

# Clear terminal
if __my_shell_has clear
  function c; command clear; end
end

# Greeting (only define if fortune exists)
if __my_shell_has fortune
  function fish_greeting    
    set -l cols red green brown yellow blue magenta purple cyan white
    set -l i (math "("(random)" % 9)+1")
    set_color $cols[$i]
    fortune -a
    echo
  end
end

# ============================================================================
# Directory Navigation
# ============================================================================

# Dynamic directory navigation aliases
function cdh; cd ~/ $argv; echo "You are at $HOME"; end
function ..; cd ../ $argv; end
function ...; cd ../../ $argv; end
function ....; cd ../../../ $argv; end
function .....; cd ../../../../ $argv; end
function ......; cd ../../../../../ $argv; end
# Alternative syntax
function .1; cd ../ $argv; end
function .2; cd ../../ $argv; end
function .3; cd ../../../ $argv; end
function .4; cd ../../../../ $argv; end
function .5; cd ../../../../../ $argv; end

# ============================================================================
# File Listing
# ============================================================================

# ls wrapper (keeps your original behavior, but uses __my_shell_has)
if __my_shell_has ls; and __my_shell_has getopt
  function ls
    set -l param
    if command ls --version > /dev/null 2>&1
      set -a param --color --group-directories-first
    end

    set -l args (getopt -s sh l $argv 2>/dev/null)
    if test "$args" = ' -l --'
      if __my_shell_has ll
        command ll -hGg $param $argv
      else
        command ls $param $argv
      end
    else
      command ls $param $argv
    end
  end
end

# ll wrapper: if an external ll exists, prefer it; else fallback to ls -lh
if __my_shell_has ll
  function ll; command ll -hGg --group-directories-first $argv; end
else
  function ll; command ls -lh $argv; end
end

if __my_shell_has dir
  function dir
    set -l param

    # If this is GNU dir (supports --version), enable GNU-only niceties
    if command dir --version >/dev/null 2>&1
      set -a param --color --group-directories-first
      if isatty 1
        set -a param --indicator-style=classify
      end
    end

    command dir $param $argv
  end
else
  function dir
    command ls -C -b $argv
  end
end

# Prefer external "ll" if available; else prefer "vdir" if available; else fallback to "ls -l -b"
if __my_shell_has ll
  function vdir; command ll -hGg $argv; end
else if __my_shell_has vdir
  function vdir
    set -l param
    if command dir --version >/dev/null 2>&1
      set -a param --color --group-directories-first
    end
    command vdir $param $argv
  end
else
  function vdir; command ls -l -b $argv; end
end

# Basic listing aliases
function j; jobs -l $argv; end
function l; ls -CF $argv; end
function la; ls -AF $argv; end
function sl; ls $argv; end

# Advanced listing functions
function laf
  set -l param
  if command ls --version > /dev/null 2>&1
    set -a param --color --group-directories-first
  end
  command find . -maxdepth 1 -type f -print0 | sed -e "s:./::g" | xargs -0r ls $param $argv
end

function ld; ls $argv -d -- *; end

function lf
  set -l param
  if command ls --version > /dev/null 2>&1
    set -a param --color --group-directories-first
  end
  command find . -maxdepth 1 -type f -a ! -iname ".*" -print0 | \
    sed -e "s:./::g" | xargs -0r ls $param $argv
end

function lh; set -l matches .*; ls $argv -Ad $matches; end
function lhd; set -l matches .*/; ls -d $matches; end
function lhf
  set -l param
  if command ls --version > /dev/null 2>&1
    set param $param --color --group-directories-first
  end
  command find . -maxdepth 1 -type f -a -iname ".*" -print0 | \
  sed -e "s:./::g" | xargs -0r ls $param $argv
end

function lad
  set -l param
  if command ls --version > /dev/null 2>&1
    set param $param --color --group-directories-first
  end
	command find . -maxdepth 1 -type d \( -not -iname "." \) -print0 | \
  sed -e "s:./::g" | xargs -0r ls -dF $param $argv
end

# Long listing functions
function lla; ll -A $argv; end
function lld; ll -dhGg */ $argv; end
function llh; set -l matches .*; ll $argv -hGgAd $matches; end
function llhd; set -l matches .*/; ll $argv -dhGg $matches; end
function llf; command find . -maxdepth 1 -type f -a ! -iname ".*" -print0 | sed -e "s:./::g"  | xargs -0r ll -hGd $argv; end
function llad; command find . -maxdepth 1 -type d \( -not -iname "." \) -print0 | sed -e "s:./::g" | xargs -0r ll -hGd $argv; end
function llaf; command find . -maxdepth 1 -type f -print0 | sed -e "s:./::g" | xargs -0r ll -hGd $argv; end
function llhf; command find . -maxdepth 1 -type f -a -iname ".*" -print0 | sed -e "s:./::g" | xargs -0r ll -hGgd $argv; end

# ============================================================================
# File Operations & Search
# ============================================================================

function FindFiles
  if test (count $argv) -eq 0
    echo "Usage: FindFiles <pattern>" >&2
    return 1
  end

  set -l searchfile $argv[1]
  command find . -type f -name "*$searchfile*"
end

# Find in current directory
function fhere; command find . -name $argv; end

# ============================================================================
# Disk Usage
# ============================================================================

if __my_shell_has du
  if command du --version >/dev/null 2>&1
    # GNU du
    function du; command du -k -d 1 -- $argv 2>/dev/null; end
    function du.; command du -k -d 0 -- $argv 2>/dev/null; end
  else
    # BSD du (macOS)
    function du; command du -k -d 1 $argv 2>/dev/null; end
    function du.; command du -k -d 0 $argv 2>/dev/null; end
  end
  if __my_shell_has ncdu
    function du2; command ncdu $argv; end
  end
else
  if __my_shell_has ncdu
    function du; command ncdu $argv; end
  end
end

# Disk usage of hidden files
if __my_shell_has du; and __my_shell_has find; and __my_shell_has awk
  function dushf
    echo "Calculating disk usage of hidden files in $PWD"

    find . \
      -path './.git' -prune -o \
      -type f -name '.*' -print0 | \
    while read -lz f
      command du -k "$f"
    end | awk '
      { sum += $1; count++ }
      END {
          printf "Hidden files: %d\n", count
          printf "Total: %d KB (~%.2f MB)\n", sum, sum/1024
      }
    '
  end
end

# Disk usage by file extension (portable: macOS + Linux)
if __my_shell_has du; and __my_shell_has mktemp; and __my_shell_has sort; and \
   __my_shell_has wc; and __my_shell_has awk; and __my_shell_has find; and __my_shell_has tr
  function dufiles
    set -l ext $argv[1]
    if test -z "$ext"
      echo "Usage: dufiles <ext>" >&2
      return 2
    end

    # Strip leading dot if user passes ".pdf"
    set ext (string trim -l -c '.' -- "$ext")

    set -l tmp (mktemp)
    or begin
      echo "mktemp failed" >&2
      return 1
    end

    # Collect per-file sizes in KB (portable: du -k)
    command find . -type f -name "*.$ext" -print0 | while read -lz f
      command du -k "$f"
    end > "$tmp"

    # Print list (sorted by size asc; numeric sort is portable)
    sort -n "$tmp"
    echo

    # Count files
    set -l count (wc -l < "$tmp" | tr -d ' ')
    echo "Number of $ext files: $count"

    # Total size in KB + MB
    set -l total_kb (awk '{s+=$1} END{print s+0}' "$tmp")
    set -l total_mb (awk -v s="$total_kb" 'BEGIN{printf "%.2f", s/1024}' </dev/null)
    echo "Total: $total_kb KB (~$total_mb MB)"

    rm -f "$tmp"
  end

  # Disk usage of directories
  function dusd
    set -l tmp (mktemp)
    or begin
      echo "mktemp failed" >&2
      return 1
    end

    command find . -maxdepth 1 -mindepth 1 -type d -print0 | while read -lz d
      set -l name (string replace -r '^\.\/' '' -- "$d")
      set -l kb (command du -sk -- "$d" | awk '{print $1}')
      printf "%s\t%s/\n" "$kb" "$name"
    end > "$tmp"

    if test -s "$tmp"
      sort -n "$tmp"
      set -l count (wc -l < "$tmp" | tr -d ' ')
      echo "Number of Dirs: $count"
    else
      echo "Number of Dirs: 0"
    end

    rm -f "$tmp"
  end
end

if __my_shell_has dfc
  function df; command dfc $argv; end
else
  function df; command df $argv; end
end

# ============================================================================
# Text Processing & Search
# ============================================================================

if __my_shell_has grep
  function grep; command grep --color=auto $argv; end
end
if __my_shell_has fgrep
  function fgrep; command fgrep --color=auto $argv; end
else if __my_shell_has grep
  function fgrep; command grep -F --color=auto $argv; end
end
if __my_shell_has egrep
  function egrep; command egrep --color=auto $argv; end
else if __my_shell_has grep
  function egrep; command grep -E --color=auto $argv; end
end

# head wrapper with optional colorizers
function head
  set -l x (tput cols)
  set x (math "$x - 1")
  set -l cmd "command head $argv | command cut -b 1-$x"

  if __my_shell_has ccze
    set cmd "$cmd | command ccze -A"
  else if __my_shell_has grc
    set cmd "grc $cmd"
  end

  eval $cmd
end

# tail wrapper with optional colorizers
function tail
  set -l x (tput cols)
  set x (math "$x - 1")
  set -l cmd "command tail $argv | command cut -b 1-$x"

  if __my_shell_has ccze
    set cmd "$cmd | command ccze -A"
  else if __my_shell_has grc
    set cmd "grc $cmd"
  end

  eval $cmd
end

# ============================================================================
# History
# ============================================================================

function h; history $argv; end
function hc; history --clear $argv; end
if __my_shell_has grep
  function hg; command history | command grep $argv; end
end
# Clear history and exit
function clhist; command history --clear; exit; end
# Statistics of history
function hs
  command history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | \
    command grep -v "./" | \
    command column -c3 -s " " -t | \
    command sort -nr | \
    command nl | \
    command head -n10
end

# ============================================================================
# System Information
# ============================================================================

# macOS memory helper (vm_stat/system_profiler)
function mem
  if not __my_shell_has vm_stat
    echo "mem: vm_stat not found" >&2
    return 127
  end
  if not __my_shell_has system_profiler
    echo "mem: system_profiler not found" >&2
    return 127
  end

  set -l FREE_BLOCKS (vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')
  set -l INACTIVE_BLOCKS (vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')
  set -l SPECULATIVE_BLOCKS (vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
  set -l TOTALRAM (system_profiler SPHardwareDataType | grep Memory | awk '{ print $2 $3}')

  set -l FREE (math "($FREE_BLOCKS+$SPECULATIVE_BLOCKS)*4096/(1024*1024)")
  set -l INACTIVE (math "$INACTIVE_BLOCKS*4096/(1024*1024)")
  set -l TOTAL (echo "scale=2; ($FREE+$INACTIVE)/1024" | bc)

  echo -n -s 'Free Memory: ' (set_color purple) $TOTAL 'GB' (set_color normal) ' of ' \
    (set_color yellow) "$TOTALRAM" (set_color normal)
end

if __my_shell_has free
  function free; command free -mt $argv; end
else if test "$_myos" = "Darwin"
  if __my_shell_has vm_stat; and __my_shell_has perl
    function free
      command vm_stat | perl -ne '
        /page size of (\d+)/ and $size=$1;
        /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mb\n", "$1:", $2 * $size / 1048576);
      ' $argv
    end
  end
end

# macOS internal IP (en0)
if __my_shell_has ifconfig; and __my_shell_has grep; and __my_shell_has cut
  function internalip
    ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2
  end
end

# Public IP helper
if __my_shell_has curl
  function myip
    command curl -fsS https://api.ipify.org
    echo
  end
else if __my_shell_has wget
  function myip
    command wget -qO- https://api.ipify.org
    echo
  end
else if __my_shell_has fetch
  function myip
    command fetch -qo - https://api.ipify.org
    echo
  end
end

function now; date +"%Y-%m-%d %T"; end
function nowtime; date +"%T"; end
function nowdate; date +"%Y-%m-%d"; end

function showpath; printf "%s\n" $PATH; end

# ============================================================================
# Process Management
# ============================================================================

if __my_shell_has grc
  function ping; command grc ping -c 10 $argv; end
  function ps; command grc ps aux $argv; end
else
  function ping; command ping -c 10 $argv; end
  function ps; command ps aux $argv; end
end

# Searchable Process Table
function psg; command ps aux | command grep -v grep | command grep -i -e VSZ -e $argv; end

function pfind
  command ps aux | grep "$argv" | command head -1 | cut -d " " -f 5
end

if __my_shell_has htop
  function top; htop -s PERCENT_CPU $argv; end
  function topme; top -u $USER $argv; end
end

if test "$_myos" = "Linux"
  if __my_shell_has ss
    function ports
      command ss -tulpn $argv
    end
  else if __my_shell_has netstat
    function ports
      command netstat -tulanp $argv
    end
  end
else if test "$_myos" = "Darwin"
  if __my_shell_has lsof
    function ports
      # TCP listen sockets (common use-case on macOS)
      command lsof -nP -iTCP -sTCP:LISTEN $argv
    end
  else if __my_shell_has netstat
    function ports
      # macOS netstat (no -p PID mapping like Linux)
      command netstat -anv -p tcp $argv
    end
  end
end

# ============================================================================
# Network
# ============================================================================

if __my_shell_has wget
  function wget; command wget -c $argv; end
end

# ============================================================================
# File Management
# ============================================================================

function mcd; command mkdir -p $argv; and command cd $argv; end
function mkd; command mkdir -pv $argv; and command cd $argv; end
function mkdir; command mkdir -p $argv; end
function rm!; command rm -rf -- $argv; end

# ============================================================================
# Package Management
# ============================================================================

# Update function definition based on system
if test "$_myos" = "Linux"
  if __my_shell_has apt-get
    function sagi; sudo apt-get install $argv; end
    function update; sudo apt-get update; and sudo apt-get upgrade; end
  else
    function update; echo "install apt-get" >&2; return 127; end
  end
else if test "$_myos" = "Darwin"
  if __my_shell_has port
    function update; sudo port selfupdate; and sudo port upgrade outdated $argv; end
  else
    if __my_shell_has brew
      function update; brew update; end
    else
      function update; echo "install MacPorts or Homebrew" >&2; return 127; end
    end
  end
else
  function update; echo "unsupported system ($_myos)" >&2; return 1; end
end

# ============================================================================
# Web Server
# ============================================================================

# Nginx functions (generic, works on both macOS and Linux)
if __my_shell_has nginx
  function nginxtest; sudo nginx -t $argv; end
  function nginxreload; sudo nginx -s reload $argv; end
end

# ============================================================================
# Image Processing
# ============================================================================

if __my_shell_has mogrify
  function webify; mogrify -resize 690\> *.png $argv; end
end

# ============================================================================
# Specialized Tools
# ============================================================================

if __my_shell_has radian
  function r; command radian $argv; end
end

function sourceme; source ~/.config/fish/config.fish $argv; end

# ============================================================================
# Cleanup
# ============================================================================

functions -e __my_shell_has
functions -e __get_os
set -e _myos
