#!/bin/zsh
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

# Prepend scripts/ to PATH
export PATH="$MY_SHELL_ROOT/scripts:$PATH"

# Source alias.zsh
if [ -f "$MY_SHELL_ROOT/alias.zsh" ]; then
    source "$MY_SHELL_ROOT/alias.zsh"
fi


# Source zsh.zsh and update prompt (Zsh-native)
# Note: zsh.zsh must NOT source bash.sh.
export MY_SHELL_OLD_PS1="$PS1"
if [ -f "$MY_SHELL_ROOT/zsh.zsh" ]; then
    source "$MY_SHELL_ROOT/zsh.zsh"
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

    # Re-source alias.zsh
    if [ -f "$MY_SHELL_ROOT/alias.zsh" ]; then
        source "$MY_SHELL_ROOT/alias.zsh"
    fi

    # Re-source zsh.zsh (do not source bash.sh)
    if [ -f "$MY_SHELL_ROOT/zsh.zsh" ]; then
        source "$MY_SHELL_ROOT/zsh.zsh"
    fi

    # Ensure prefix exists (magenta)
    if [[ "$PS1" != *"(my-shell)"* ]]; then
        PS1="%F{magenta}(my-shell)%f $PS1"
    fi

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
