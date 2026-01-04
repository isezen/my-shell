#!/bin/bash
# activate.bash - Bash environment activation
# Usage: source activate.bash

# Determine project root directory
if [ -z "$MY_SHELL_ROOT" ]; then
    MY_SHELL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Check if already activated
if [ -n "$MY_SHELL_ACTIVATED" ]; then
    echo "my-shell environment is already activated"
    return 0 2>/dev/null || true
fi

# Set activation mode (default to source if not set)
if [ -z "$MY_SHELL_ACTIVATION_MODE" ]; then
    export MY_SHELL_ACTIVATION_MODE="source"
fi

# Save PATH snapshot for exact restoration
export MY_SHELL_OLD_PATH="$PATH"

# Prepend scripts/bin/ to PATH
export PATH="$MY_SHELL_ROOT/scripts/bin:$PATH"

# Save PS1 before sourcing init
export MY_SHELL_OLD_PS1="$PS1"

# Source shell/bash/init.bash (single entrypoint)
if [ -f "$MY_SHELL_ROOT/shell/bash/init.bash" ]; then
    source "$MY_SHELL_ROOT/shell/bash/init.bash"
fi

# Activation owns the (my-shell) prefix; render it in magenta.
if [[ "$PS1" != *"(my-shell)"* ]]; then
    PS1="\[\e[0;35m\](my-shell)\[\e[0m\] $PS1"
fi

# Define colortable alias
alias colortable="$MY_SHELL_ROOT/colortable.sh"

# Reactivate function
reactivate() {
    if [ -z "$MY_SHELL_ACTIVATED" ]; then
        echo "my-shell environment is not activated"
        echo "Use 'source env/activate.bash' to activate first"
        return 1
    fi

    echo "Reloading my-shell environment files..."

    # Re-source shell/bash/init.bash
    if [ -f "$MY_SHELL_ROOT/shell/bash/init.bash" ]; then
        source "$MY_SHELL_ROOT/shell/bash/init.bash"
    fi

    # Ensure prefix exists (magenta)
    if [[ "$PS1" != *"(my-shell)"* ]]; then
        PS1="\[\e[0;35m\](my-shell)\[\e[0m\] $PS1"
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

    # Spawn marker: ./env/activate always starts a new interactive shell
    _SESSION_SPAWNED="$MY_SHELL_SESSION_SPAWNED"
    
    # Clean up activation variables
    unset MY_SHELL_ACTIVATED
    unset MY_SHELL_ACTIVATION_MODE
    unset MY_SHELL_ROOT
    unset MY_SHELL_SESSION_SPAWNED
    unset MY_SHELL_SPAWNED_SHELL
    
    # Clean up temporary artifacts (best-effort)
    if [ -n "$MY_SHELL_TMPDIR" ] && [ -d "$MY_SHELL_TMPDIR" ]; then
        rm -rf "$MY_SHELL_TMPDIR" 2>/dev/null || true
    fi
    unset MY_SHELL_TMPDIR
    
    # Remove functions
    unset -f deactivate
    unset -f reactivate

    echo "- my-shell environment deactivated"
    echo "- Bye..."
    

    # If this Bash session was spawned by ./env/activate, exit after cleanup.
    if [ "$_SESSION_SPAWNED" = "1" ]; then
        exit 0
    fi
}

export MY_SHELL_ACTIVATED=1
export MY_SHELL_ROOT
echo "- my-shell environment activated (bash)"
