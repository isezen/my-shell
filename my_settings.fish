#!/bin/env fish
# 2016-03-28
# sezenismail@gmail.com
# Shiny bash promt support and
# dircolors support

set -xU CLICOLOR 1

function c; clear; end
function cdh; cd ~/ $argv; echo "You are at $HOME"; end

function fish_greeting
	command --search fortune >/dev/null; and begin
		set -l cols red green brown yellow blue magenta purple cyan white
		set i (math "("(random)" % 9)+1")
		set_color $cols[$i]
		fortune -a
		echo
	end
end


function fish_prompt
	set -l last_status $status

	# Just calculate this once, to save a few cycles when displaying the prompt
	if not set -q __fish_prompt_hostname
		set -g __fish_prompt_hostname (hostname|cut -d . -f 1)
	end

	set -l normal (set_color normal)

	# Hack; fish_config only copies the fish_prompt function (see #736)
	if not set -q -g __fish_classic_git_functions_defined
		set -g __fish_classic_git_functions_defined

		function __fish_repaint_user --on-variable fish_color_user --description "Event handler, repaint when fish_color_user changes"
			if status --is-interactive
				commandline -f repaint
			end
		end

		function __fish_repaint_host --on-variable fish_color_host --description "Event handler, repaint when fish_color_host changes"
			if status --is-interactive
				commandline -f repaint
			end
		end

		function __fish_repaint_status --on-variable fish_color_status --description "Event handler; repaint when fish_color_status changes"
			if status --is-interactive
				commandline -f repaint
			end
		end

		function __fish_repaint_bind_mode --on-variable fish_key_bindings --description "Event handler; repaint when fish_key_bindings changes"
			if status --is-interactive
				commandline -f repaint
			end
		end

		# initialize our new variables
		if not set -q __fish_classic_git_prompt_initialized
			set -qU fish_color_user; or set -U fish_color_user -o green
			set -qU fish_color_host; or set -U fish_color_host -o cyan
			set -qU fish_color_status; or set -U fish_color_status red
			set -U __fish_classic_git_prompt_initialized
		end
	end

	set -l color_cwd
	set -l prefix
	switch $USER
	case root toor
		if set -q fish_color_cwd_root
			set color_cwd $fish_color_cwd_root
		else
			set color_cwd $fish_color_cwd
		end
		set suffix '#'
	case '*'
		set color_cwd $fish_color_cwd
		set suffix '>'
	end

	set -l prompt_status
	if test $last_status -ne 0
		set prompt_status ' ' (set_color $fish_color_status) "[$last_status]" "$normal"
	end

	set -l mode_str
	switch "$fish_key_bindings"
	case '*_vi_*' '*_vi'
		# possibly fish_vi_key_bindings, or custom key bindings
		# that includes the name "vi"
		set mode_str (
			echo -n " "
			switch $fish_bind_mode
			case default
				set_color --bold --background red white
				echo -n "[N]"
			case insert
				set_color --bold green
				echo -n "[I]"
			case visual
				set_color --bold magenta
				echo -n "[V]"
			end
			set_color normal
		)
	end

	echo -n -s (set_color $fish_color_host) "$__fish_prompt_hostname" $normal ☘' ' (set_color $color_cwd) (prompt_pwd) $normal (__fish_git_prompt) $normal $prompt_status "$mode_str" (set_color $fish_color_status) "> " $normal
end


function free
	command --search free >/dev/null; and begin
		free -mt $argv
	end; or begin
	    vm_stat | perl -ne '/page size of (\d+)/ and $size=$1;    /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f Mb\n", "$1:",     $2 * $size / 1048576);' $argv;
	end
end

function FindFiles
	set _searchfile "$1"
  set _search_command 'find . -type f \( -name "*'$_searchfile'*" \)'
  eval "$_search_command"
end

function df
    command --search hash dfc >/dev/null; and begin
        dfc $argv
    end; or begin
        command df $argv
    end
end

function dir
  set -l param
  command --search dir >/dev/null; and begin
    if command dir --version > /dev/null 2>&1
      set param $param --color --group-directories-first
      if isatty 1
        set param $param --indicator-style=classify
      end
    end
    command dir $param $argv
  end; or begin
    eval "ls -C -b"
  end
end

function du; command du -ahd 1 $argv 2>/dev/null; end
function du.; command du -ahd 0 $argv 2>/dev/null;end
function du2
  command --search ncdu >/dev/null; and begin
	 command ncdu $argv
	end; or begin
		echo Install ncdu
	end
end

function grep; command grep --color=auto $argv;end

function h;history $argv;end
function hc;history --clear $argv;end
function hg;history | grep $argv;end

function head
    set x (tput cols)
    set x (math "$x - 1")
    set cmd "command head $argv | command cut -b 1-$x"
    command --search ccze >/dev/null; and begin
        set cmd "$cmd | command ccze -A"
    end; or begin
        command --search grc >/dev/null; and begin
            set cmd "grc $cmd"
        end; or begin
        end
    end
    eval $cmd
end

function internalip
    ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2
end

function laf
  set -l param
  if command ls --version > /dev/null 2>&1
    set param $param --color --group-directories-first
  end
	find . -maxdepth 1 -type f -print0 | sed -e "s:./::g" | xargs -0r ls $param $argv
end

function ld; ls $argv -d -- *; end

function lf
  set -l param
  if command ls --version > /dev/null 2>&1
    set param $param --color --group-directories-first
  end
  find . -maxdepth 1 -type f -a ! -iname ".*" -print0 | sed -e "s:./::g"  | xargs -0r ls $param $argv
end

function lh
    set -l matches .*
    ls $argv -Ad $matches
end

function lhd
    set -l matches .*/
    ls -d $matches;
end

function lhf
  set -l param
  if command ls --version > /dev/null 2>&1
    set param $param --color --group-directories-first
  end
  find . -maxdepth 1 -type f -a -iname ".*" -print0 | sed -e "s:./::g" | xargs -0r ls $param $argv
end

function ll
	command --search ll >/dev/null; and begin
	  command ll -hGg --group-directories-first $argv
	end; or begin
	  ls -lh $argv
	end
end

function lla; ll -A $argv;end

function llad
	find . -maxdepth 1 -type d \( -not -iname "." \) -print0 | sed -e "s:./::g" | xargs -0r ll -hGd $argv
end

function llaf
	find . -maxdepth 1 -type f -print0 | sed -e "s:./::g" | xargs -0r ll -hGd $argv
end

function lld;ll -dhGg */ $argv;end

function llf
	find . -maxdepth 1 -type f -a ! -iname ".*" -print0 | sed -e "s:./::g"  | xargs -0r ll -hGd $argv
end

function llh
    set -l matches .*
    ll $argv -hGgAd $matches;
end

function llhd
    set -l matches .*/
    ll $argv -dhGg $matches;
end

function llhf
	find . -maxdepth 1 -type f -a -iname ".*" -print0 | sed -e "s:./::g" | xargs -0r ll -hGgd $argv
end

function ls
  command --search ls >/dev/null; and begin
    set -l param
    if command ls --version > /dev/null 2>&1
      set param $param --color --group-directories-first
    end

    set args (getopt -s sh l $argv 2>/dev/null)
    if [ $args = ' -l --' ]
      command --search ll >/dev/null; and begin
        command ll -hGg $param $argv
      end; or begin
         command ls $param $argv
      end
    else
      command ls $param $argv
    end
  end; or begin
    echo "ls does not exist"
  end
end

function j; jobs -l $argv; end

function l; ls -CF $argv; end

function la; ls -AF $argv; end

function lad
  set -l param
  if command ls --version > /dev/null 2>&1
    set param $param --color --group-directories-first
  end
	find . -maxdepth 1 -type d \( -not -iname "." \) -print0 | sed -e "s:./::g" | xargs -0r ls -dF $param $argv
end

function mcd; mkdir -p $argv; cd $argv;end

function mem
  set -l FREE_BLOCKS (vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')
  set -l INACTIVE_BLOCKS (vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')
  set -l SPECULATIVE_BLOCKS (vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
  set -l TOTALRAM (system_profiler SPHardwareDataType | grep Memory | awk '{ print $2 $3}')

  set -l FREE (math "($FREE_BLOCKS+$SPECULATIVE_BLOCKS)*4096/(1024*1024)")

  set -l INACTIVE (math "$INACTIVE_BLOCKS*4096/(1024*1024)")
  set -l TOTAL (echo "scale=2; ($FREE+$INACTIVE)/1024" | bc)
  echo -n -s 'Free Memory: ' (set_color purple) $TOTAL 'GB' (set_color normal) ' of ' (set_color yellow) "$TOTALRAM" (set_color normal)
end

function mkdir;command mkdir -pv $argv;end

function myip;curl http://ipecho.net/plain; echo $argv;end

function now;date +"%Y-%m-%d %T";end
function nowtime;date +"%T";end
function nowdate;date +"%Y-%m-%d";end

function path;echo -e $PATH | sed 's/ /\n/g';end

function pfind
    command ps aux | grep "$argv" | command head -1 | cut -d " " -f 5
end

function ping
  command --search grc >/dev/null; and begin
		grc ping -c 10 $argv
	end; or begin
		ping -c 10 $argv
	end
end

function ports;netstat -tulanp $argv;end

# function print_files
# 	while IFS=$'\t' read -r size line
#     printf "%s\t%s" $size "$line"
#     [[ -d $line ]]; and printf "/"
#     echo
#     set x (math "$x + 1")
#   end < echo "$1"
# end; funcsave print_files

function ps
	command --search grc >/dev/null; and begin
		grc ps aux $argv
	end; or begin
		ps aux $argv
	end
end

# function psg;ps aux $argv | grep -v grep | grep -i -e VSZ -e;end

function rm!;rm -Rf $argv;end

function set_dircolors
	if not test -e ~/.dircolors
	  curl -sLo ~/.dircolors https://raw.github.com/trapd00r/LS_COLORS/master/LS_COLORS
	end
	command --search ls >/dev/null; and begin
		if command ls --version > /dev/null 2>&1
			if not set -q LS_COLORS
				if type -f dircolors >/dev/null
					if test -e ~/.dircolors
						eval (dircolors -c ~/.dircolors | sed 's/>&\/dev\/null$//')
					end
				end
			end
		end
	end
end

function sl;ls $argv;end

function sourceme;source ~/.config/fish/config.fish $argv;end


function tail
    set x (tput cols)
    set x (math "$x - 1")
    set cmd "command tail $argv | command cut -b 1-$x"
    command --search ccze >/dev/null; and begin
        set cmd "$cmd | command ccze -A"
    end; or begin
        command --search grc >/dev/null; and begin
            set cmd "grc $cmd"
        end; or begin
        end
    end
    eval $cmd
end

function top
	command --search htop >/dev/null; and begin
		htop -s PERCENT_CPU $argv
	end; or begin
		command top $argv
	end
end

function topme;top -u $USER $argv;end

function update
    if [ (uname) = 'Darwin' ]
        if type -q port
            sudo port selfupdate; and sudo port upgrade outdated $argv
        else
            echo install macports
        end
    else if [ (uname) = 'Linux' ]
        if [ (lsb_release -si) = 'Ubuntu' ]
            if type -q apt-get
                sudo apt-get update; and sudo apt-get upgrade
            else
               echo install apt-get
            end
        end
    end
end

function vdir
  set -l param
 	command --search ll >/dev/null; and begin
	  command ll -hGg $argv
	end; or begin
	  command --search vdir >/dev/null; and begin
	    if dir --version >/dev/null 2>&1
	      set param $param --color --group-directories-first
	    end
	    command vdir $param $argv
	  end; or begin
	    eval "ls -l -b"
	  end
	end
end

function webify
	command --search mogrify >/dev/null; and begin
		mogrify -resize 690\> *.png $argv;
	end; or begin
		echo install mogrify
	end
end

function wget;command wget -c $argv;end

function r;command radian $argv;end

