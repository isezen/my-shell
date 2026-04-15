# my-shell

A collection of shell environment settings, aliases, and utility scripts for bash and fish shells. Designed to work on both Linux and macOS.

[![CI](https://github.com/isezen/my-shell/workflows/CI/badge.svg)](https://github.com/isezen/my-shell/actions)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://www.shellcheck.net/)
[![Tests](https://img.shields.io/badge/tests-130%20passing-brightgreen)](tests/)

## Features

### 🎯 Shell Aliases & Functions
- **File operations**: Enhanced `ls`, `ll`, `find`, and directory navigation aliases
- **System information**: Memory usage, IP address, disk usage utilities
- **History management**: Enhanced history commands with search and statistics
- **Quick navigation**: Shortcuts for directory navigation (`.1`, `.2`, `..`, `...`, etc.)
- **Time utilities**: Quick date/time commands (`now`, `nowtime`, `nowdate`)

### 🐟 Fish Shell Support
- Full fish shell configuration (`shell/fish/init.fish`)
- Fish-specific functions and aliases
- Colorful prompt with git integration
- Directory colors support

### 🛠️ Utility Scripts
- **`ll`**: Colorful long listing with enhanced formatting (cross-platform, byte-identical output between Linux and macOS — see [Behavior Contract](#behavior-contract))
- **`dus`**, **`dusf`**, **`dusf.`**: _Feature-frozen_ legacy disk-usage helpers (current dir summary, regular-file breakdown, hidden-file breakdown). **Require GNU coreutils**: on macOS install via `sudo port install coreutils` (MacPorts) or `brew install coreutils` (Homebrew), then prepend the gnubin directory to `PATH`. Without GNU `ls` the scripts exit 2 with an actionable error (no cryptic BSD usage noise). These scripts are kept for compatibility only; for new use prefer **[ncdu](https://dev.yorhel.nl/ncdu)** (interactive TUI), **[dust](https://github.com/bootandy/dust)** (Rust, tree view), or **[duf](https://github.com/muesli/duf)** (disk-free overview).

### ✅ Quality Assurance
- **ShellCheck**: All scripts pass static analysis
- **BATS Tests**: 130 automated tests covering shell aliases, install flow, `ll` family wrapper, and platform-specific GNU/BSD implementations
- **CI/CD**: Automated testing on Linux and macOS
- **Pre-commit hooks**: Code quality checks before commit

## Behavior Contract

The `ll` family (`ll`, `ll_linux`, `ll_macos`) follows a **test-locked behavior contract**:

- `ll_linux` and `ll_macos` share a single render/format/color layer in
  `scripts/bin/ll_common.awk` (BSD-awk compatible, mandatory for both
  drivers). `ll_linux`'s GNU `ls -l` ingress parser lives in
  `scripts/bin/ll_linux.awk`.
- **Cross-driver parity is byte-level locked.** Under the baseline
  environment (`LC_ALL=C TZ=UTC LL_NO_COLOR=1 LL_NOW_EPOCH=1577836800`),
  `ll_linux` and `ll_macos` produce byte-identical output for every
  supported fixture case. `tests/ll/20_baseline_snapshot.bats` enforces
  three invariants simultaneously: each driver matches its own locked
  baseline, and the two baselines match each other.
- Behavior is documented and locked by existing tests as a current-state
  specification; untested behaviors are explicitly marked as
  **UNSPECIFIED** and not guaranteed.
- Snapshot captures live under `tests/fixtures/ll_baseline/`. Regenerate
  intentionally with `make baseline-regen`, verify with `make baseline-check`.

For complete behavior documentation, see [`docs/LL_SPECS.md`](docs/LL_SPECS.md).

## Installation

### Quick Install (One-liner)

**Install both shell settings and utility scripts (default):**
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)"
```

**Install only shell settings:**
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)" -- --settings-only
```

**Install only utility scripts:**
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)" -- --scripts-only
```

**Install without prompting (overwrite existing files):**
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/isezen/my-shell/master/install.sh)" -- -y
```

The installer will:
- Detect your shell (bash, zsh, or fish)
- Install shell settings to `~/.my-shell/<shell>/`:
  - `init.*` - Shell initialization entrypoint
  - `aliases.*` - Aliases and functions
  - `prompt.*` - Prompt configuration
  - `env.*` - Environment settings
- Install utility scripts to `/usr/local/bin` (or `/opt/homebrew/bin` on macOS with Homebrew):
  - `ll` - Colorful long listing
  - `dus` - Disk usage script
  - `dusf` - File-based disk usage
  - `dusf.` - Alternative disk usage format
- Add necessary configuration to your shell's RC file

### Manual Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/isezen/my-shell.git
   cd my-shell
   ```

2. **Run the installer:**
   ```sh
   ./install.sh --local
   ```

   Or with custom options:
   ```sh
   # Install only settings
   ./install.sh --local --settings-only

   # Install only scripts
   ./install.sh --local --scripts-only

   # Install with custom repo root
   ./install.sh --local --repo-root /path/to/repo

   # Install without prompting
   ./install.sh --local -y
   ```

### Uninstallation

**Shell Settings:**
- Delete `~/.my-shell/` directory
- Remove source lines from your `~/.profile`, `~/.bash_profile`, `~/.zshrc`, or `~/.config/fish/config.fish`

**Utility Scripts:**
```sh
sudo rm /usr/local/bin/ll /usr/local/bin/ll_linux /usr/local/bin/ll_macos \
        /usr/local/bin/ll_common.awk /usr/local/bin/ll_linux.awk \
        /usr/local/bin/dus /usr/local/bin/dusf /usr/local/bin/dusf.
```

## Usage Examples

### File Operations

```bash
# Enhanced ls commands
ls          # Colorized, directories first
ll          # Long format with colors
la          # All files including hidden
lf          # Only regular files
ld          # Only directories

# Quick navigation
cdh         # Go to home directory
.1          # Go up 1 directory
.2          # Go up 2 directories
..          # Go up 1 directory (alternative)
...         # Go up 2 directories (alternative)

# Find files
fhere filename    # Find files in current directory
FindFiles name   # Find files with pattern
```

### System Information

```bash
# Memory usage (macOS)
mem

# IP address
myip

# Disk usage
du          # Current directory, 1 level deep
du.         # Current directory only
du2         # Interactive disk usage (ncdu if available)

# Network
ports       # Show listening ports
```

### History Management

```bash
h           # Show history
hg pattern  # Search history
hs          # History statistics (top 10 commands)
```

### Time Utilities

```bash
now         # Current time
nowtime     # Current time (alias)
nowdate     # Current date
```

### Utility Scripts

```bash
# Colorful long listing
ll -h /path/to/directory
ll -d       # Directories only
ll --help   # Show help

# Disk usage analysis
dus         # Current directory
dus -f      # Files only
dus -d      # Directories only
dus -v      # Verbose output
```

## Project Structure

```
my-shell/
├── shell/                # Shell-specific configurations
│   ├── bash/            # Bash configuration
│   │   ├── init.bash    # Bash initialization entrypoint
│   │   ├── aliases.bash # Bash aliases and functions
│   │   ├── prompt.bash  # Bash prompt configuration
│   │   └── env.bash     # Bash environment settings
│   ├── zsh/             # Zsh configuration
│   │   ├── init.zsh     # Zsh initialization entrypoint
│   │   ├── aliases.zsh  # Zsh aliases and functions
│   │   ├── prompt.zsh   # Zsh prompt configuration
│   │   └── env.zsh      # Zsh environment settings
│   └── fish/            # Fish configuration
│       ├── init.fish    # Fish initialization entrypoint
│       ├── aliases.fish # Fish aliases and functions
│       ├── prompt.fish  # Fish prompt configuration
│       └── env.fish     # Fish environment settings
├── scripts/
│   ├── bin/             # Utility scripts (executables)
│   │   ├── ll           # Platform dispatcher wrapper
│   │   ├── ll_linux     # GNU/Linux implementation
│   │   ├── ll_macos     # BSD/macOS implementation
│   │   ├── dus          # Disk usage script
│   │   ├── dusf         # File-based disk usage
│   │   └── dusf.        # Alternative disk usage
│   └── dev/             # Development tools (added to PATH when activated)
│       ├── ll-compare   # Compare ll implementations
│       ├── ls-compare   # Compare against ls -l
│       └── run-shellcheck  # Project-wide ShellCheck runner
├── env/                 # Environment activation scripts
│   ├── activate         # Global shell switcher
│   ├── activate.bash    # Bash activation
│   ├── activate.zsh     # Zsh activation
│   └── activate.fish    # Fish activation
├── install.sh           # Unified installation script
├── tests/               # BATS test suite (130 tests)
│   ├── alias.bats       # Tests for aliases.bash
│   ├── bash.bats        # Tests for prompt.bash and env.bash
│   ├── alias-sync.bats  # Alias synchronization tests
│   ├── ll/              # Platform-independent wrapper tests
│   │   └── 10_wrapper_stub.bats
│   ├── ll_linux/        # GNU/Linux-specific tests
│   │   ├── 00_harness.bash
│   │   └── 10_core.bats
│   ├── ll_macos/        # BSD/macOS-specific tests
│   │   ├── 00_harness.bash
│   │   └── 10_core.bats
│   ├── scripts_ll.bats  # Legacy ll tests
│   └── scripts_dus.bats # Tests for dus script
├── Makefile             # Development commands
├── .pre-commit-config.yaml  # Pre-commit hooks
├── .shellcheckrc        # ShellCheck configuration
└── CONTRIBUTING.md      # Contribution guidelines
```

## Development

### Prerequisites

- **ShellCheck**: `brew install shellcheck` (macOS) or `sudo apt-get install shellcheck` (Linux)
- **BATS**: `brew install bats-core` (macOS) or `sudo apt-get install bats` (Linux)
- **Fish**: `brew install fish` (macOS) or `sudo apt-get install fish` (Linux)
- **pre-commit**: `pip install pre-commit` (optional but recommended)

### Development Commands

```bash
# Show all available commands
make help

# Code quality
make lint          # Run all linting checks
make lint-bash     # Check bash/sh scripts
make lint-fish     # Check fish scripts
make alias-sync    # Verify alias synchronization
make check         # Run all checks (lint + alias-sync)

# Testing
make test          # Run all tests (BATS + linting)
make test-bats     # Run only BATS tests
make test-ll       # Platform-aware ll test suite (auto-detects OS)
make test-ll-common   # Platform-independent wrapper tests
make test-ll-linux    # GNU/Linux-specific tests
make test-ll-macos    # BSD/macOS-specific tests
make test-ll-all      # All test suites (unsuitable ones will soft-skip)
make test-act         # Run GitHub Actions locally (requires Docker)

# Formatting
make format        # Format fish scripts
make format-fish   # Format fish scripts with fish_indent

# Pre-commit hooks
make install-hooks # Install pre-commit hooks

# Cleanup
make clean         # Remove temporary files
```

### Running Tests

```bash
# Run all tests
make test-bats

# Run platform-aware ll test suite
make test-ll              # Auto-detects platform (macOS or Linux)
make test-ll-common       # Platform-independent wrapper tests
make test-ll-macos        # macOS-specific BSD tests
make test-ll-linux        # Linux-specific GNU tests

# Run specific test file
bats tests/alias.bats
bats tests/ll/10_wrapper_stub.bats
bats tests/ll_macos/10_core.bats

# Verbose output
bats -v tests/alias.bats

# Development tools for ll implementations
scripts/dev/ll-compare ll_linux ll_macos  # Compare implementations
scripts/dev/ls-compare ll_macos           # Compare against ls -l
```

### Code Quality

All scripts are checked with:
- **ShellCheck**: Static analysis for bash/sh scripts
- **Fish syntax check**: `fish -n` for fish scripts
- **Pre-commit hooks**: Automatic checks before commit
- **CI/CD**: Automated testing on push/PR

## Compatibility

- ✅ **Linux** (Ubuntu, Debian, Fedora, etc.)
- ✅ **macOS** (Darwin)
- ✅ **Bash** 4.0+
- ✅ **Fish** 2.2+
- ✅ **Zsh** (with bash compatibility)

## Testing

The project includes a comprehensive test suite with **130 tests** covering:
- Alias definitions, sync between bash/zsh/fish, and shell-specific behavior
- `install.sh` flow (settings/scripts modes, dry-run, RC file edits)
- `ll` wrapper dispatch contract (`LL_IMPL_PATH`, `LL_IMPL`, `LL_SCRIPT` precedence)
- `ll_linux` and `ll_macos` platform implementations against real GNU and BSD coreutils
- Byte-level cross-driver parity baseline locked under deterministic env

See [tests/README.md](tests/README.md) for detailed testing information.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Key points:
- Use feature branches
- All PRs require review
- Tests required for new features
- Follow coding standards (ShellCheck compliance)

## CI/CD

The project uses GitHub Actions for continuous integration:
- **Automated testing** on Linux (Ubuntu) and macOS
- **Platform-specific test suites**: `make test-ll` auto-detects OS and runs appropriate tests
- **ShellCheck validation** with severity=warning threshold
- **Fish syntax checking** with `fish -n`
- **Alias synchronization** verification across bash/zsh/fish
- **Test coverage reports** with formatted output in GitHub summary
- **Pre-commit hooks** for code quality enforcement

See [.github/workflows/ci.yml](.github/workflows/ci.yml) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Ismail SEZEN**
- Email: sezenismail@gmail.com
- GitHub: [@isezen](https://github.com/isezen)

## Acknowledgments

- [ShellCheck](https://www.shellcheck.net/) - Shell script static analysis
- [BATS](https://github.com/bats-core/bats-core) - Bash Automated Testing System
- [Fish Shell](https://fishshell.com/) - Friendly interactive shell
- [pre-commit](https://pre-commit.com/) - Git hooks framework

## Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/isezen/my-shell/issues)
- 💡 **Feature Requests**: [Open an issue](https://github.com/isezen/my-shell/issues)
- 📖 **Documentation**: See [CONTRIBUTING.md](CONTRIBUTING.md) and [tests/README.md](tests/README.md)
- ❓ **Questions**: Open a discussion in [GitHub Discussions](https://github.com/isezen/my-shell/discussions)

---

**Note**: This project has been actively developed since 2014 and is compatible with both Linux and macOS. If you encounter any compatibility issues, please open an issue.
