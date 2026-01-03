#!/bin/bash
(
[ "$LS_COLORS" ] || eval "$(dircolors)"
[ "$LS_COLORS" ] || eval "$(TERM=xterm dircolors)"
printf '%s' "$LS_COLORS"
) | tr : '\n' |
sed 's/\([^=]*\)=\(.*\)/\x1b[\2m\1\x1b[0m\t\2/'
