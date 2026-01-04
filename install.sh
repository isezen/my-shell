#!/bin/bash
# Unified installer for my-shell
# Installs both shell settings and utility scripts
#
# Usage:
#   Remote installation:
#     sh -c "$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)"
#     sh -c "$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)" -- --settings-only
#     sh -c "$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)" -- --scripts-only
#
#   Local installation:
#     ./install.sh --local
#     ./install.sh --local --repo-root /path/to/repo
#     ./install.sh --local --user
#     ./install.sh --local --bin-prefix /custom/path
#     ./install.sh --local --dry-run=/tmp/test-install
#
# Options:
#   --local              Use local repository instead of remote
#   --repo-root PATH     Specify repository root path (for local mode)
#   --settings-only      Install only shell settings (aliases, prompt, etc.)
#   --scripts-only       Install only utility scripts (ll, dus, etc.)
#   --user               Install scripts to $HOME/.local/bin (user mode, no sudo required)
#   --bin-prefix PATH    Install scripts to custom PATH (overrides --user and MY_SHELL_BIN_PREFIX)
#   --dry-run=PATH       Sandbox mode: install to sandbox directory instead of real system (PATH must be absolute)
#   -y, --yes            Overwrite existing files without prompting
#   -h, --help           Show help message
#
# Environment variables:
#   MY_SHELL_REMOTE_BASE    Override remote base URL
#   MY_SHELL_BIN_PREFIX     Override binary installation prefix (overridden by --bin-prefix)
#
# BIN_PREFIX precedence (highest to lowest):
#   1. --bin-prefix PATH (command line)
#   2. MY_SHELL_BIN_PREFIX (environment variable)
#   3. --user flag => $HOME/.local/bin
#   4. Default => /usr/local/bin (requires sudo)

# Helper functions
die() {
  echo "${1}" >&2
  exit 1
}

log() {
  echo "${1}"
}

ensure_dir() {
  local dir="$1"
  if ! mkdir -p "$dir" 2>/dev/null; then
    die "Could not create directory: $dir"
  fi
}

ensure_file() {
  local file="$1"
  local dir
  dir="$(dirname "$file")"
  ensure_dir "$dir"
  if ! touch "$file" 2>/dev/null; then
    die "Could not create file: $file"
  fi
}

prompt_overwrite() {
  local dest="$1"
  if [ "$YES" = "1" ]; then
    return 0
  fi
  # Dry-run mode requires -y/--yes to avoid interactive prompts
  if [ "$DRY_RUN" = "1" ]; then
    die "Dry-run mode requires -y/--yes to avoid interactive prompts"
  fi
  if [ -f "$dest" ] || [ -e "$dest" ]; then
    echo "File exists: $dest"
    echo -n "Overwrite? [y/N] "
    read -r ans
    case "$ans" in
      [yY]|[yY][eE][sS])
        return 0
        ;;
      *)
        die "Aborted by user."
        ;;
    esac
  fi
  return 0
}

append_line_if_missing() {
  local file="$1"
  local line="$2"
  ensure_file "$file"
  if ! grep -qF "$line" "$file" 2>/dev/null; then
    echo "" >> "$file"
    echo "$line" >> "$file"
  fi
}

fetch_or_copy() {
  local rel_path="$1"
  local dest_path="$2"
  local file_mode="${3:-0755}"
  
  prompt_overwrite "$dest_path"
  
  if [ "$SOURCE_MODE" = "local" ]; then
    local src="$REPO_ROOT/$rel_path"
    if [ ! -f "$src" ]; then
      die "Missing local source: $src"
    fi
    cp "$src" "$dest_path" || die "Could not copy $src to $dest_path"
  else
    local base="${MY_SHELL_REMOTE_BASE:-https://raw.githubusercontent.com/isezen/my-shell/master}"
    local url="$base/$rel_path"
    curl -fsSL "$url" > "$dest_path" || die "Could not download $url"
  fi
  
  chmod "$file_mode" "$dest_path" || die "Could not set permissions on $dest_path"
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --local              Use local repository instead of remote
  --repo-root PATH     Specify repository root path (for local mode)
  --settings-only      Install only shell settings (aliases, prompt, etc.)
  --scripts-only       Install only utility scripts (ll, dus, etc.)
  --user               Install scripts to \$HOME/.local/bin (user mode)
  --bin-prefix PATH    Install scripts to custom PATH (overrides --user and MY_SHELL_BIN_PREFIX)
  --dry-run=PATH       Sandbox mode: install to sandbox directory instead of real system (PATH must be absolute)
  -y, --yes            Overwrite existing files without prompting
  -h, --help           Show this help message

Examples:
  # Install both settings and scripts (default)
  sh -c "\$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)"

  # Install only settings
  sh -c "\$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)" -- --settings-only

  # Install from local repository (script must be in repo root)
  ./install.sh --local

  # Install with explicit repo root (recommended if script is not in repo root)
  ./install.sh --local --repo-root /path/to/repo

  # Install to user directory (no sudo required)
  ./install.sh --local --user

  # Install to custom directory
  ./install.sh --local --bin-prefix /custom/path

  # Dry-run (sandbox mode) - install to sandbox directory for testing
  ./install.sh --local --repo-root /path/to/repo --dry-run=/tmp/test-install

Environment variables:
  MY_SHELL_REMOTE_BASE    Override remote base URL
  MY_SHELL_BIN_PREFIX     Override binary installation prefix (overridden by --bin-prefix)
EOF
}

# Parse command line arguments
SOURCE_MODE="remote"
REPO_ROOT=""
YES=0
DO_SETTINGS=1
DO_SCRIPTS=1
SHOW_HELP=0
SETTINGS_ONLY_SET=0
SCRIPTS_ONLY_SET=0
USER_MODE=0
BIN_PREFIX_OVERRIDE=""
DRY_RUN=0
DRY_RUN_ROOT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --local)
      SOURCE_MODE="local"
      shift
      ;;
    --repo-root)
      if [ -z "$2" ]; then
        echo "Error: --repo-root requires a path argument" >&2
        echo "" >&2
        usage >&2
        exit 1
      fi
      REPO_ROOT="$2"
      shift 2
      ;;
    --settings-only)
      DO_SETTINGS=1
      DO_SCRIPTS=0
      SETTINGS_ONLY_SET=1
      shift
      ;;
    --scripts-only)
      DO_SETTINGS=0
      DO_SCRIPTS=1
      SCRIPTS_ONLY_SET=1
      shift
      ;;
    -y|--yes)
      YES=1
      shift
      ;;
    --user)
      USER_MODE=1
      shift
      ;;
    --bin-prefix)
      if [ -z "$2" ]; then
        echo "Error: --bin-prefix requires a path argument" >&2
        echo "" >&2
        usage >&2
        exit 1
      fi
      BIN_PREFIX_OVERRIDE="$2"
      shift 2
      ;;
    --dry-run=*)
      DRY_RUN_ROOT="${1#*=}"
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      SHOW_HELP=1
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# Validate conflicting options
if [ "$SETTINGS_ONLY_SET" = "1" ] && [ "$SCRIPTS_ONLY_SET" = "1" ]; then
  echo "Error: --settings-only and --scripts-only cannot be used together" >&2
  echo "" >&2
  usage >&2
  exit 1
fi

# Validate dry-run
if [ "$DRY_RUN" = "1" ]; then
  if [ -z "$DRY_RUN_ROOT" ]; then
    die "Error: --dry-run requires a path argument"
  fi
  if [ "${DRY_RUN_ROOT#/}" = "$DRY_RUN_ROOT" ]; then
    die "Error: --dry-run path must be absolute (start with /)"
  fi
  # Normalize trailing slash
  DRY_RUN_ROOT="${DRY_RUN_ROOT%/}"
fi

# Show help if requested
if [ "$SHOW_HELP" = "1" ]; then
  usage
  exit 0
fi

# Validate --repo-root usage
if [ -n "$REPO_ROOT" ] && [ "$SOURCE_MODE" = "remote" ]; then
  die "Error: --repo-root can only be used with --local"
fi

# If local mode and no repo root specified, try to detect from script location
if [ "$SOURCE_MODE" = "local" ] && [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
fi

# Detect shell
shell_name="$(basename "$SHELL")"
if [ "$shell_name" != "bash" ] && [ "$shell_name" != "zsh" ] && [ "$shell_name" != "fish" ]; then
  die "Unsupported shell: $shell_name. Supported shells: bash, zsh, fish"
fi

# Set up effective paths (dry-run sandbox mapping)
if [ "$DRY_RUN" = "1" ]; then
  EFFECTIVE_HOME="$DRY_RUN_ROOT/HOME"
else
  EFFECTIVE_HOME="$HOME"
fi

# Determine RC file using EFFECTIVE_HOME
RC_BASE="$EFFECTIVE_HOME"
EFFECTIVE_RC_FILE=""
if [ "$shell_name" = "bash" ]; then
  # Always use .bash_profile for deterministic behavior
  EFFECTIVE_RC_FILE="${RC_BASE}/.bash_profile"
elif [ "$shell_name" = "zsh" ]; then
  EFFECTIVE_RC_FILE="${RC_BASE}/.zshrc"
elif [ "$shell_name" = "fish" ]; then
  if ! command -v fish >/dev/null 2>&1; then
    die "fish binary not found. Please install fish shell first."
  fi
  EFFECTIVE_RC_FILE="${RC_BASE}/.config/fish/config.fish"
fi

# Ensure RC file exists
ensure_file "$EFFECTIVE_RC_FILE"

# Detect OS early (die on unknown OS)
# OS check is only a guard; default BIN_PREFIX is identical on macOS and Linux
OS="$(uname -s)"
if [ "$OS" != "Darwin" ] && [ "$OS" != "Linux" ]; then
  die "Unsupported OS: $OS. Supported OS: Darwin (macOS), Linux"
fi

# Determine BIN_PREFIX_REAL with precedence:
# 1) --bin-prefix (command line, highest priority)
# 2) MY_SHELL_BIN_PREFIX (env var)
# 3) --user flag => $HOME/.local/bin
# 4) OS default => /usr/local/bin
if [ -n "$BIN_PREFIX_OVERRIDE" ]; then
  BIN_PREFIX_REAL="$BIN_PREFIX_OVERRIDE"
elif [ -n "$MY_SHELL_BIN_PREFIX" ]; then
  BIN_PREFIX_REAL="$MY_SHELL_BIN_PREFIX"
elif [ "$USER_MODE" = "1" ]; then
  BIN_PREFIX_REAL="$HOME/.local/bin"
else
  BIN_PREFIX_REAL="/usr/local/bin"
fi

# Map to EFFECTIVE_BIN_PREFIX (dry-run sandbox mapping)
if [ "$DRY_RUN" = "1" ]; then
  if [ "$USER_MODE" = "1" ] && [ -z "$BIN_PREFIX_OVERRIDE" ] && [ -z "$MY_SHELL_BIN_PREFIX" ]; then
    # User mode: map to EFFECTIVE_HOME/.local/bin
    EFFECTIVE_BIN_PREFIX="$EFFECTIVE_HOME/.local/bin"
  elif [ "${BIN_PREFIX_REAL#"$HOME"}" != "$BIN_PREFIX_REAL" ]; then
    # BIN_PREFIX_REAL starts with $HOME/: map to EFFECTIVE_HOME + suffix
    EFFECTIVE_BIN_PREFIX="$EFFECTIVE_HOME${BIN_PREFIX_REAL#"$HOME"}"
  else
    # Absolute path: map to DRY_RUN_ROOT + path
    EFFECTIVE_BIN_PREFIX="$DRY_RUN_ROOT$BIN_PREFIX_REAL"
  fi
else
  EFFECTIVE_BIN_PREFIX="$BIN_PREFIX_REAL"
fi

# Set EFFECTIVE_INSTALL_DIR
EFFECTIVE_INSTALL_DIR="$EFFECTIVE_HOME/.my-shell"

# Dry-run banner: show all effective paths
if [ "$DRY_RUN" = "1" ]; then
  log "DRY-RUN: sandbox=$DRY_RUN_ROOT"
  log "DRY-RUN: effective_home=$EFFECTIVE_HOME"
  log "DRY-RUN: effective_rc=$EFFECTIVE_RC_FILE"
  log "DRY-RUN: effective_bin_prefix=$EFFECTIVE_BIN_PREFIX (real=$BIN_PREFIX_REAL)"
  log ""
fi

# Install settings if requested
if [ "$DO_SETTINGS" = "1" ]; then
  EFFECTIVE_SHELL_DIR="${EFFECTIVE_INSTALL_DIR}/${shell_name}"
  ensure_dir "$EFFECTIVE_SHELL_DIR"
  
  # Determine files to install based on shell
  if [ "$shell_name" = "bash" ]; then
    FILES="init.bash aliases.bash prompt.bash env.bash"
  elif [ "$shell_name" = "zsh" ]; then
    FILES="init.zsh aliases.zsh prompt.zsh env.zsh"
  elif [ "$shell_name" = "fish" ]; then
    FILES="init.fish aliases.fish prompt.fish env.fish"
  fi
  
  log "Installing my-shell configuration for $shell_name..."
  for file in $FILES; do
    rel_path="shell/${shell_name}/${file}"
    dest_path="${EFFECTIVE_SHELL_DIR}/${file}"
    
    log "Installing: $file"
    if [ "$SOURCE_MODE" = "local" ]; then
      log "  Copying from local repository: $REPO_ROOT/$rel_path"
    else
      base="${MY_SHELL_REMOTE_BASE:-https://raw.githubusercontent.com/isezen/my-shell/master}"
      log "  Downloading from: $base/$rel_path"
    fi
    fetch_or_copy "$rel_path" "$dest_path" 0644
    log "  Done."
  done
  log ""
  
  # Add source line to RC file
  SOURCE_LINE=""
  if [ "$DRY_RUN" = "1" ]; then
    # Dry-run: use EFFECTIVE_HOME (absolute sandbox path)
    if [ "$shell_name" = "bash" ]; then
      SOURCE_LINE="source \"$EFFECTIVE_HOME/.my-shell/bash/init.bash\""
    elif [ "$shell_name" = "zsh" ]; then
      SOURCE_LINE="source \"$EFFECTIVE_HOME/.my-shell/zsh/init.zsh\""
    elif [ "$shell_name" = "fish" ]; then
      SOURCE_LINE="source \"$EFFECTIVE_HOME/.my-shell/fish/init.fish\""
    fi
  else
    # Normal mode: use $HOME literal (portable for shell rc)
    if [ "$shell_name" = "bash" ]; then
      SOURCE_LINE="source \"\$HOME/.my-shell/bash/init.bash\""
    elif [ "$shell_name" = "zsh" ]; then
      SOURCE_LINE="source \"\$HOME/.my-shell/zsh/init.zsh\""
    elif [ "$shell_name" = "fish" ]; then
      SOURCE_LINE="source \"\$HOME/.my-shell/fish/init.fish\""
    fi
  fi
  
  append_line_if_missing "$EFFECTIVE_RC_FILE" "$SOURCE_LINE"
fi

# Install scripts if requested
if [ "$DO_SCRIPTS" = "1" ]; then
  # Ensure EFFECTIVE_BIN_PREFIX directory exists and is writable
  if ! mkdir -p "$EFFECTIVE_BIN_PREFIX" 2>/dev/null; then
    # Cannot create directory
    if [ "$BIN_PREFIX_REAL" = "/usr/local/bin" ]; then
      die "Cannot write to $EFFECTIVE_BIN_PREFIX. Please run with sudo: sudo $0 [args], OR use --user, OR use --bin-prefix PATH"
    else
      die "Cannot write to $EFFECTIVE_BIN_PREFIX. Please check permissions or choose a writable path with --bin-prefix PATH"
    fi
  fi
  
  # Check if directory is writable (mkdir -p might succeed even if not writable)
  if [ ! -w "$EFFECTIVE_BIN_PREFIX" ]; then
    if [ "$BIN_PREFIX_REAL" = "/usr/local/bin" ]; then
      die "Cannot write to $EFFECTIVE_BIN_PREFIX. Please run with sudo: sudo $0 [args], OR use --user, OR use --bin-prefix PATH"
    else
      die "Cannot write to $EFFECTIVE_BIN_PREFIX. Please check permissions or choose a writable path with --bin-prefix PATH"
    fi
  fi
  
  SCRIPTS="ll dus dusf dusf."
  
  log "Installing utility scripts to $EFFECTIVE_BIN_PREFIX..."
  for script in $SCRIPTS; do
    rel_path="scripts/bin/${script}"
    dest_path="${EFFECTIVE_BIN_PREFIX}/${script}"
    
    log "Installing script: $script"
    if [ "$SOURCE_MODE" = "local" ]; then
      log "  Copying from local repository: $REPO_ROOT/$rel_path"
    else
      base="${MY_SHELL_REMOTE_BASE:-https://raw.githubusercontent.com/isezen/my-shell/master}"
      log "  Downloading from: $base/$rel_path"
    fi
    fetch_or_copy "$rel_path" "$dest_path"
    log "  Done."
  done
  log ""
  
  # Add PATH line to RC file (idempotent)
  if [ "$shell_name" = "fish" ]; then
    PATH_LINE="set -gx PATH \"$EFFECTIVE_BIN_PREFIX\" \$PATH"
  else
    PATH_LINE="export PATH=\"$EFFECTIVE_BIN_PREFIX:\$PATH\""
  fi
  
  append_line_if_missing "$EFFECTIVE_RC_FILE" "$PATH_LINE"
fi

log "Installation complete!"
log "Restart shell or source your rc file: source $EFFECTIVE_RC_FILE"
