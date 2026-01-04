#!/bin/bash
# 2016-03-27
# sezenismail@gmail.com
# sudo sh -c "$(curl -sL https://git.io/vVfYB)"
# Install my shell scripts
#

function die() {
  echo "${1}" >&2
  exit 1
}

# Source provider layer if available (for local mode)
# If running from repo, use local provider
if [ -f "$(dirname "$0")/lib/provider.sh" ]; then
    source "$(dirname "$0")/lib/provider.sh"
fi

# Parse command line arguments
MY_SHELL_SOURCE_MODE="remote"
MY_SHELL_REPO_ROOT=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            MY_SHELL_SOURCE_MODE="local"
            shift
            ;;
        --repo-root)
            MY_SHELL_REPO_ROOT="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Usage: $0 [--local] [--repo-root PATH]" >&2
            exit 1
            ;;
    esac
done

# If local mode and no repo root specified, try to detect from script location
if [ "$MY_SHELL_SOURCE_MODE" = "local" ] && [ -z "$MY_SHELL_REPO_ROOT" ]; then
    MY_SHELL_REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
fi

function save() {
  local fbase="$1"
  local fname="${_PREFIX}/$fbase"
  local rel_path="scripts/bin/$fbase"
  
  echo "Installing script: $fbase"
  
  if [ "$MY_SHELL_SOURCE_MODE" = "local" ] && [ -f "$MY_SHELL_REPO_ROOT/$rel_path" ]; then
    echo "Copying from local repository: $MY_SHELL_REPO_ROOT/$rel_path"
    cp "$MY_SHELL_REPO_ROOT/$rel_path" "${fname}" || die "Couldn't copy script from $MY_SHELL_REPO_ROOT/$rel_path"
  else
    local url="$_URLM/$rel_path"
    echo "Downloading from: ${url}"
    curl -fsSL "${url}" > "${fname}" || die "Couldn't download script from ${url}"
  fi
  
  chmod +x "${fname}"
  echo "Done."
  echo ""
}

SHELL=$(echo "${SHELL}" | tr / "\n" | tail -1)
# shellcheck disable=SC2016
_PREFIX='/usr/local/bin'
_URLM="https://raw.githubusercontent.com/isezen/my-shell/master"

mkdir -p "$_PREFIX"
echo "Checking if PATH contains ${_PREFIX}"

# Determine profile file based on shell
SCRIPT=""
if [ "$SHELL" = "bash" ]; then
    if [ -f "${HOME}/.bash_profile" ]; then
        SCRIPT="${HOME}/.bash_profile"
    elif [ -f "${HOME}/.profile" ]; then
        SCRIPT="${HOME}/.profile"
    else
        SCRIPT="${HOME}/.bash_profile"
    fi
elif [ "$SHELL" = "zsh" ]; then
    SCRIPT="${HOME}/.zshrc"
elif [ "$SHELL" = "fish" ]; then
    SCRIPT="${HOME}/.config/fish/config.fish"
else
    die "Unsupported shell: $SHELL"
fi

# Create profile file if it doesn't exist
if [ ! -f "$SCRIPT" ]; then
    mkdir -p "$(dirname "$SCRIPT")"
    touch "$SCRIPT"
fi

if [[ ":$PATH:" != *":$_PREFIX:"* ]]; then
  if ! grep -q "$_PREFIX" "$SCRIPT" 2>/dev/null; then
    echo "Appending export command to ${SCRIPT}..."
    if [ "$SHELL" = "fish" ]; then
        echo "" >> "${SCRIPT}"
        echo "set -gx PATH \"$_PREFIX\" \$PATH" >> "${SCRIPT}"
    else
        echo "" >> "${SCRIPT}"
        echo "export PATH=\"$_PREFIX:\$PATH\"" >> "${SCRIPT}"
    fi
    echo "Done."
  else
    echo "PATH already configured in ${SCRIPT}"
  fi
else
  echo "PATH already contains ${_PREFIX}"
fi
echo ""

for s in ll dus dusf dusf.; do save "$s"; done

echo "The next time you log in, shell scripts will be enabled."
