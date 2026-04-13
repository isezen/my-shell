#!/bin/zsh
# env/activate.zsh
# activate.zsh - Zsh environment activation
# Usage: source activate.zsh

# Determine project root directory
if [ -z "$MY_SHELL_ROOT" ]; then
    MY_SHELL_ROOT="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
fi

# Check if already activated
if [ -n "$MY_SHELL_ACTIVATED" ]; then
    echo "my-shell environment is already activated"
    return 0
fi

# Set activation mode (default to source if not set)
if [ -z "$MY_SHELL_ACTIVATION_MODE" ]; then
    export MY_SHELL_ACTIVATION_MODE="source"
fi

# Save PATH snapshot for exact restoration
export MY_SHELL_OLD_PATH="$PATH"

# Optional BSD-only mode: remove GNU coreutils gnubin paths.
if [ "${LL_BSD_USERLAND:-}" = "1" ] || [ "${LL_NO_GNUBIN:-}" = "1" ]; then
    typeset -a _my_shell_path_raw _my_shell_path_parts
    _my_shell_path_raw=("${(@s/:/)PATH}")
    for _my_shell_path in "${_my_shell_path_raw[@]}"; do
        case "$_my_shell_path" in
            /opt/local/libexec/gnubin|/usr/local/opt/coreutils/libexec/gnubin|/opt/homebrew/opt/coreutils/libexec/gnubin)
                continue
                ;;
            /opt/local/bin)
                if [ -x /opt/local/bin/gawk ] || [ -x /opt/local/bin/gdate ] || [ -x /opt/local/bin/gtouch ]; then
                    continue
                fi
                ;;
        esac
        _my_shell_path_parts+=("$_my_shell_path")
    done
    PATH="${(j/:/) _my_shell_path_parts}"
    export PATH
fi

# Prepend scripts/bin/ and scripts/dev/ to PATH
export PATH="$MY_SHELL_ROOT/scripts/bin:$MY_SHELL_ROOT/scripts/dev:$PATH"

# Save PS1 before sourcing init
export MY_SHELL_OLD_PS1="$PS1"

# Source shell/zsh/init.zsh (single entrypoint)
if [ -f "$MY_SHELL_ROOT/shell/zsh/init.zsh" ]; then
    source "$MY_SHELL_ROOT/shell/zsh/init.zsh"
fi

# Activation owns the (my-shell) prefix; render it in magenta.
if [[ "$PS1" != *"(my-shell)"* ]]; then
    PS1="%F{magenta}(my-shell)%f $PS1"
fi

# Define colortable alias
alias colortable="$MY_SHELL_ROOT/colortable.sh"

# Reactivate function
reactivate() {
    if [ -z "$MY_SHELL_ACTIVATED" ]; then
        echo "my-shell environment is not activated"
        echo "Use 'source env/activate.zsh' to activate first"
        return 1
    fi

    echo "Reloading my-shell environment files..."

    # Remove existing prefix if present (to avoid duplication)
    if [[ "$PS1" == *"(my-shell)"* ]]; then
        # Remove the prefix pattern: %F{magenta}(my-shell)%f
        PS1="${PS1//%F{magenta}(my-shell)%f /}"
    fi

    # Re-source shell/zsh/init.zsh
    if [ -f "$MY_SHELL_ROOT/shell/zsh/init.zsh" ]; then
        source "$MY_SHELL_ROOT/shell/zsh/init.zsh"
    fi

    # Always add prefix after re-sourcing (prompt.zsh may have reset PS1)
    PS1="%F{magenta}(my-shell)%f $PS1"

    # Redefine colortable alias
    alias colortable="$MY_SHELL_ROOT/colortable.sh"

    echo "my-shell environment reloaded"
}

# Deactivate function
deactivate() {
    if [ -z "$MY_SHELL_ACTIVATED" ]; then
        echo "my-shell environment is not activated"
        return 1
    fi

    # Restore PATH to exact snapshot
    export PATH="$MY_SHELL_OLD_PATH"
    unset MY_SHELL_OLD_PATH

    # Restore PS1
    if [ -n "$MY_SHELL_OLD_PS1" ]; then
        export PS1="$MY_SHELL_OLD_PS1"
        unset MY_SHELL_OLD_PS1
    fi


    # Remove colortable alias
    unalias colortable 2>/dev/null || true

    # Capture spawn flag (./env/activate always spawns a new shell)
    _SPAWNED_SESSION="$MY_SHELL_SESSION_SPAWNED"

    # Clean up activation variables
    unset MY_SHELL_ACTIVATED
    unset MY_SHELL_ACTIVATION_MODE
    unset MY_SHELL_ROOT

    # Clean up temporary artifacts (best-effort)
    if [ -n "$MY_SHELL_TMPDIR" ] && [ -d "$MY_SHELL_TMPDIR" ]; then
        rm -rf "$MY_SHELL_TMPDIR" 2>/dev/null || true
    fi
    unset MY_SHELL_TMPDIR

    # Spawn marker cleanup
    unset MY_SHELL_SESSION_SPAWNED
    unset MY_SHELL_SPAWNED_SHELL

    # Remove functions
    unset -f deactivate
    unset -f reactivate

    echo "- my-shell environment deactivated"
    echo "- Bye..."

    # If this session was spawned by ./env/activate, exit back to the parent shell.
    if [ "$_SPAWNED_SESSION" = "1" ]; then
        exit
    fi
}

export MY_SHELL_ACTIVATED=1
export MY_SHELL_ROOT
echo "- my-shell environment activated (zsh)"
