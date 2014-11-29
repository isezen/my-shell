
_myos=`uname`
if [[ "$_myos" == 'Linux' ]]; then
  _distro=$(lsb_release -si)
elif [[ "$_myos" == 'Darwin' ]]; then
  _distro=$OSTYPE
fi

alias sourceme='source ~/.bash_profile'

# Find Files in current directory
_findRegularFiles='find . -maxdepth 1 -type f -a ! -iname ".*" -print0 | sed -e "s:./::g" '
_findAllFiles='find . -maxdepth 1 -type f -print0 | sed -e "s:./::g" '
_findHiddenFiles='find . -maxdepth 1 -type f -a -iname ".*" -print0 | sed -e "s:./::g" '
_findAllDirectories='find . -maxdepth 1 -type d \( -not -iname "." \) -print0 | sed -e "s:./::g" '

FindFiles () {
  _searchfile='$1'
  _search_command='find . -type f \( -name "*'$_searchfile'*" \)'
  eval $_search_command
}

# Listing aliases
alias ls='ls --color --group-directories-first' # Standart
alias sl='ls' # Typo correction
alias la='ls -AF' # All
alias lh='ls -dF .[^.]*' # Hidden

# List directories
# http://superuser.com/questions/335376/how-to-list-folders-using-bash-commands
alias ld='ls -d -- */' # regular directories
alias lad=$_findAllDirectories' | xargs -0r ls -dF --color' # All directories
alias lhd='ls -d .[^.]*/' # Hidden directories

# List Files
# https://unix.stackexchange.com/questions/48492/list-only-regular-files-but-not-directories-in-current-directory
alias lf=$_findRegularFiles' | xargs -0r ls --color'
alias laf=$_findAllFiles' | xargs -0r ls --color' # List all files
alias lhf=$_findHiddenFiles' | xargs -0r ls --color'

# Colorize dir and vdir
alias dir='dir --color=auto --group-directories-first'
alias vdir='vdir --color=auto --group-directories-first'

# Colorize grep and friends
alias grep='grep --color=auto --exclude-dir=\.svn'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# More easy directory changing
alias cdh="cd ~/" # Go to Home
# Expamples:
# ".." or ".1" -> Up 1 level
# "..." or ".2" -> Up 2 levels
# "...." or ".3" -> Up 3 levels
dotSlash=""
dot=".."
for i in 1 2 3 4 5
do
  dotSlash=${dotSlash}'../';
  baseName=".${i}"
  alias $baseName="cd ${dotSlash}"
  alias $dot="cd $dotSlash"
  dot=${dot}'.';
done



# Long listings
# if you have ll, use it instead of ls
if hash ll 2>/dev/null; then
  _ll='ll -h --group-directories-first'
else
  _ll='ls -lhF --color'
fi

alias ll="$_ll -F"
alias llad=$_findAllDirectories' | xargs -0r '$_ll' -dF' # All directories
alias llf=$_findRegularFiles' | xargs -0r '$_ll' -d'    # List regular files
alias llaf=$_findAllFiles' | xargs -0r '$_ll' -d '      # List all files + hidden
alias llhf=$_findHiddenFiles' | xargs -0r '$_ll' -d'    # Only hidden files
alias lla=$_ll' -A' # All
alias llh=$_ll' -d .[^.]*' # Hidden

alias lld='\ll -dh */' # regular directories
alias llhd='\ll -dh .[^.]*/' # Hidden directories

# Clear terminal and list files
alias c="clear"

# -C=list entries by columns
alias l='ls -CF'

# Permanently delete command
alias 'rm!=/bin/rm -Rf'

# Find in current directory
alias fhere="find . -name "

# Use pydf instead of df if exist
if hash pydf 2>/dev/null; then alias df='pydf'; fi

# Use dfc instead of df if exist
if hash dfc 2>/dev/null; then alias df='dfc'; fi

dushf () {
  echo "Calculating disk usage of all hidden files in $PWD"
  _filelist=$(find . -type f -a -iname "*.pdf" -print0 | xargs -r0 \du -ach | sort -h);
  echo "Number of files:"$(expr $(echo "$_filelist"| wc -l) - 1);
  tail -n 1 <<< "$_filelist"
}

dufiles () {
  file="$1"
  _search_command='find . -type f \( -name "*.'$1'" \) -print0 | xargs -r0 \du -ch | sort -h'
  _filelist=$(eval $_search_command)
  echo "$_filelist"
  echo "Number of $1 files:"$(expr $(echo "$_filelist"| wc -l) - 1);
  tail -n 1 <<< "$_filelist"
}

# Only Directories
dusd () {
  let x=-1
  _filelist=$(eval $_findAllDirectories' | xargs -r0 \du -hcd 0 | sed -r "s:./::" | sort -h');
  print_files "$_filelist"
  echo "Number of Dirs:"$(expr $(echo "$_filelist"| wc -l) - 1);
}

print_files () {
  while IFS=$'\t' read -r size line;
    do printf "%s\t%s" $size "$line"
    [[ -d $line ]] && printf "/"
    echo
    x=$(( $x + 1 ))
  done <<< "$1"
}

# alias du='du -ach --max-depth=1 2> >(grep -v "^du: cannot \(access\|read\)" >&2)'
alias du='du -ahd 1 '
alias du.='\du -ahd 0 2> >(grep -v "^du: cannot \(access\|read\)" >&2)'

# Show output in MB
# Show total for RAM + swap
alias free='free -mt'

# List Process Table
alias ps='ps auxf'

# Searchable Process Table
alias psg="ps aux | grep -v grep | grep -i -e VSZ -e"

# Parent Directory + Verbose output
alias mkdir="mkdir -pv"

# Continue to download in case of interruption
alias wget="wget -c"

alias h='history'

# Search history
alias histg="history | grep"

alias topme='top -U $USER' # Valid for both linux and darwin
# Use htop instead of top if exist
if hash htop 2>/dev/null; then
  alias top='htop'
  alias topme='top -u $USER'
fi

# Interactive disk usage
if hash ncdu 2>/dev/null; then alias du2='ncdu'; fi

# Show my ip
alias myip="curl http://ipecho.net/plain; echo"

# resize images for web if mogrify exist
# This will resize all of the PNG images in the current directory, only if they are wider than 690px
if hash mogrify 2>/dev/null; then alias webify='mogrify -resize 690\> *.png'; fi

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Clear history
alias clhist='cat /dev/null > ~/.bash_history && history -c && exit'

# Statistics of history
stathist () {
  history | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n10;
}

# mkdir a directory and move into that directory
mcd () { mkdir -p $1;cd $1; }


alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%Y-%m-%d"'

# Stop after sending count ECHO_REQUEST packets #
alias ping='ping -c 5'

alias ports='netstat -tulanp'

if [[ "$_distro" == 'Ubuntu' ]]; then
  # Easy install command
  alias sagi='sudo apt-get install'
  # update on one command for ubuntu
  alias update='sudo apt-get update && sudo apt-get upgrade'
  #Web Server Stuff
  alias nginxreload='sudo /usr/sbin/nginx -s reload'
  alias nginxtest='sudo /usr/sbin/nginx -t'
fi
