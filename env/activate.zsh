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

# Source alias.sh
if [ -f "$MY_SHELL_ROOT/alias.sh" ]; then
    source "$MY_SHELL_ROOT/alias.sh"
fi

# Source bash.sh and update prompt
if [ -f "$MY_SHELL_ROOT/bash.sh" ]; then
    export MY_SHELL_OLD_PS1="$PS1"
    source "$MY_SHELL_ROOT/bash.sh"
    export PS1="(my-shell) $PS1"
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

    # Re-source alias.sh
    if [ -f "$MY_SHELL_ROOT/alias.sh" ]; then
        source "$MY_SHELL_ROOT/alias.sh"
    fi

    # Re-source bash.sh and update prompt
    if [ -f "$MY_SHELL_ROOT/bash.sh" ]; then
        source "$MY_SHELL_ROOT/bash.sh"
        # Update prompt (add prefix if not present)
        if [[ "$PS1" != "(my-shell)"* ]]; then
            export PS1="(my-shell) $PS1"
        fi
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

    # Check for shell switching (Scenario 3.2)
    _SWITCHED_FROM="$MY_SHELL_SWITCHED_FROM"
    
    # Clean up activation variables
    unset MY_SHELL_ACTIVATED
    unset MY_SHELL_ACTIVATION_MODE
    unset MY_SHELL_ROOT
    
    # Clean up temporary artifacts (best-effort)
    if [ -n "$MY_SHELL_TMPDIR" ] && [ -d "$MY_SHELL_TMPDIR" ]; then
        rm -rf "$MY_SHELL_TMPDIR" 2>/dev/null || true
        unset MY_SHELL_TMPDIR
    fi
    
    # Remove functions
    unset -f deactivate
    unset -f reactivate

    echo "- my-shell environment deactivated"
    echo "- Bye..."
    
    # If switched from another shell, return to it (Scenario 3.2)
    if [ -n "$_SWITCHED_FROM" ]; then
        unset MY_SHELL_SWITCHED_FROM
        echo "- Returning to $_SWITCHED_FROM shell..."
        exec "$_SWITCHED_FROM"
    fi
}

export MY_SHELL_ACTIVATED=1
export MY_SHELL_ROOT
echo "- my-shell environment activated (zsh)"
