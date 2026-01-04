#!/bin/bash
# Provider functions for remote/local file fetching
# This module provides a unified interface for fetching files either from
# a remote URL (GitHub raw) or from a local repository path.

# Detect source mode
# Returns: "remote" or "local"
detect_source_mode() {
    if [ -n "$MY_SHELL_SOURCE_MODE" ]; then
        echo "$MY_SHELL_SOURCE_MODE"
    elif [ -n "$MY_SHELL_REPO_ROOT" ] && [ -d "$MY_SHELL_REPO_ROOT" ]; then
        echo "local"
    else
        echo "remote"
    fi
}

# Get remote base URL
# Returns: Remote base URL for GitHub raw content
get_remote_base() {
    echo "${MY_SHELL_REMOTE_BASE:-https://raw.githubusercontent.com/isezen/my-shell/master}"
}

# Fetch file (remote or local)
# Args:
#   $1: Relative path from repo root (e.g., "scripts/bin/ll")
#   $2: Destination path where file should be saved
# Returns: 0 on success, 1 on failure
fetch_file() {
    local rel_path="$1"
    local dest_path="$2"
    local mode
    mode=$(detect_source_mode)
    
    if [ "$mode" = "local" ]; then
        local repo_root="${MY_SHELL_REPO_ROOT:-$(pwd)}"
        if [ -f "$repo_root/$rel_path" ]; then
            cp "$repo_root/$rel_path" "$dest_path" || return 1
        else
            echo "Error: File not found: $repo_root/$rel_path" >&2
            return 1
        fi
    else
        local remote_base
        remote_base=$(get_remote_base)
        curl -fsSL "$remote_base/$rel_path" > "$dest_path" || return 1
    fi
}

