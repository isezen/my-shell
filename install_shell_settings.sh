#!/bin/bash
# 2016-03-27
# sezenismail@gmail.com
# sh -c "$(curl -sL https://git.io/vVftO)"
# Install my shell settings and aliases.
#

function die() {
  echo "${1}" >&2
  exit 1
}

# Source provider layer if available (for local mode)
# If running from repo, use local provider
if [ -f "$(dirname "$0")/lib/provider.sh" ]; then
    # shellcheck disable=SC1091
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

SHELL=$(echo "${SHELL}" | tr / "\n" | tail -1)

# Determine target directory and profile file
INSTALL_DIR="${HOME}/.my-shell"
SHELL_DIR="${INSTALL_DIR}/${SHELL}"
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
    echo "Make sure you have fish 2.2 or later. Your version is:"
    fish -v
    echo ""
else
    die "Unsupported shell: $SHELL. Supported shells: bash, zsh, fish"
fi

# Create install directory
mkdir -p "$SHELL_DIR" || die "Could not create directory: $SHELL_DIR"

# Create profile file if it doesn't exist
if [ ! -f "$SCRIPT" ]; then
    mkdir -p "$(dirname "$SCRIPT")"
    touch "$SCRIPT"
fi

# List of files to copy for each shell
if [ "$SHELL" = "bash" ]; then
    FILES=("init.bash" "aliases.bash" "prompt.bash" "env.bash")
elif [ "$SHELL" = "zsh" ]; then
    FILES=("init.zsh" "aliases.zsh" "prompt.zsh" "env.zsh")
elif [ "$SHELL" = "fish" ]; then
    FILES=("init.fish" "aliases.fish" "prompt.fish" "env.fish")
fi

# Copy files
echo "Installing my-shell configuration for $SHELL..."
for file in "${FILES[@]}"; do
    rel_path="shell/${SHELL}/${file}"
    dest_path="${SHELL_DIR}/${file}"
    
    echo "Installing: $file"
    
    if [ "$MY_SHELL_SOURCE_MODE" = "local" ] && [ -f "$MY_SHELL_REPO_ROOT/$rel_path" ]; then
        echo "  Copying from local repository: $MY_SHELL_REPO_ROOT/$rel_path"
        cp "$MY_SHELL_REPO_ROOT/$rel_path" "$dest_path" || die "Could not copy $file"
    else
        remote_base="${MY_SHELL_REMOTE_BASE:-https://raw.githubusercontent.com/isezen/my-shell/master}"
        url="${remote_base}/${rel_path}"
        echo "  Downloading from: $url"
        curl -fsSL "$url" > "$dest_path" || die "Could not download $file"
    fi
    
    chmod +x "$dest_path"
    echo "  Done."
done
echo ""

# Add source line to profile
SOURCE_LINE=""
if [ "$SHELL" = "bash" ]; then
    SOURCE_LINE="source \"\$HOME/.my-shell/bash/init.bash\""
elif [ "$SHELL" = "zsh" ]; then
    SOURCE_LINE="source \"\$HOME/.my-shell/zsh/init.zsh\""
elif [ "$SHELL" = "fish" ]; then
    SOURCE_LINE="source \"\$HOME/.my-shell/fish/init.fish\""
fi

# Check if source line already exists
if grep -qF "$SOURCE_LINE" "$SCRIPT" 2>/dev/null; then
    echo "Source line already exists in ${SCRIPT}"
else
    echo "Adding source line to ${SCRIPT}..."
    echo "" >> "$SCRIPT"
    echo "$SOURCE_LINE" >> "$SCRIPT"
    echo "Done."
fi

echo ""
echo "The next time you log in, shell settings will be enabled."
