#!/usr/bin/env fish
# activate.fish - Fish environment activation
# Usage: source activate.fish

# Determine project root directory
if not set -q MY_SHELL_ROOT
    set -gx MY_SHELL_ROOT (cd (dirname (status -f))/.. && pwd)
end

# Check if already activated
if set -q MY_SHELL_ACTIVATED
    echo "my-shell environment is already activated"
    return 0
end

# Set activation mode (default to source if not set)
if not set -q MY_SHELL_ACTIVATION_MODE
    set -gx MY_SHELL_ACTIVATION_MODE "source"
end

# Save PATH snapshot for exact restoration
set -gx MY_SHELL_OLD_PATH $PATH

# Prepend scripts/bin/ to PATH
set -gx PATH "$MY_SHELL_ROOT/scripts/bin" $PATH

# Source shell/fish/init.fish (single entrypoint)
if test -f "$MY_SHELL_ROOT/shell/fish/init.fish"
    source "$MY_SHELL_ROOT/shell/fish/init.fish"
end

# Define colortable function (global scope)
function colortable -d "Display color table"
    bash "$MY_SHELL_ROOT/colortable.sh" $argv
end

# Define prompt prefix function (global scope)
function __my_shell_prompt_prefix
    # Use magenta color for (my-shell) prefix to make it visually distinct
    set_color magenta
    echo -n "(my-shell) "
    set_color normal
end

# Backup and replace fish_prompt (Scenario 7.2)
if not functions -q __my_shell_old_fish_prompt
    functions -c fish_prompt __my_shell_old_fish_prompt
    function fish_prompt
        __my_shell_prompt_prefix
        __my_shell_old_fish_prompt
    end
end

# Reactivate function (global scope)
function reactivate -d "Reload my-shell environment files"
    if not set -q MY_SHELL_ACTIVATED
        echo "my-shell environment is not activated"
        echo "Use 'source env/activate.fish' to activate first"
        return 1
    end

    echo "Reloading my-shell environment files..."

    # Re-source shell/fish/init.fish
    if test -f "$MY_SHELL_ROOT/shell/fish/init.fish"
        source "$MY_SHELL_ROOT/shell/fish/init.fish"
    end

    # Redefine colortable function
    function colortable
        bash "$MY_SHELL_ROOT/colortable.sh" $argv
    end

    echo "my-shell environment reloaded"
end

# Deactivate function (global scope)
function deactivate -d "Deactivate my-shell environment"
    if not set -q MY_SHELL_ACTIVATED
        echo "my-shell environment is not activated"
        return 1
    end

    # Normal deactivation (Scenario 3.1) or Fish exec deactivation (Scenario 3.3)
    # Restore PATH to exact snapshot
    set -gx PATH $MY_SHELL_OLD_PATH
    set -e MY_SHELL_OLD_PATH

    # Restore fish_prompt (Scenario 7.2)
    if functions -q __my_shell_old_fish_prompt
        functions -e fish_prompt
        functions -c __my_shell_old_fish_prompt fish_prompt
        functions -e __my_shell_old_fish_prompt
    end
    functions -e __my_shell_prompt_prefix
    functions -e colortable
    functions -e deactivate
    functions -e reactivate

    # Check if this session was spawned by ./env/activate before cleanup
    set -l spawned_session 0
    if set -q MY_SHELL_SESSION_SPAWNED
        if test "$MY_SHELL_SESSION_SPAWNED" = "1"
            set spawned_session 1
        end
    end

    # Clean up activation variables
    set -e MY_SHELL_ACTIVATED
    set -e MY_SHELL_ACTIVATION_MODE
    set -e MY_SHELL_ROOT
    if set -q MY_SHELL_SESSION_SPAWNED
        set -e MY_SHELL_SESSION_SPAWNED
    end
    if set -q MY_SHELL_SPAWNED_SHELL
        set -e MY_SHELL_SPAWNED_SHELL
    end

    # Backward-compat marker (optional)
    if set -q MY_SHELL_FISH_SPAWNED
        set -e MY_SHELL_FISH_SPAWNED
    end

    echo "- my-shell environment deactivated"
    echo "- Bye..."
    
    # If this session was spawned by ./env/activate, exit back to the parent shell.
    if test $spawned_session -eq 1
        exit
    end
end

# Set activation variables
set -gx MY_SHELL_ACTIVATED 1
echo "- my-shell environment activated (fish)"
