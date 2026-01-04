#!/usr/bin/env fish
# 2016-03-28
# sezenismail@gmail.com
# Fish environment settings (dircolors, etc.)

set -xU CLICOLOR 1

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

