# my-shell

A collection of shell environment settings, aliases, and utility scripts for bash and fish shells. Designed to work on both Linux and macOS.

[![CI](https://github.com/isezen/my-shell/workflows/CI/badge.svg)](https://github.com/isezen/my-shell/actions)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-passing-brightgreen)](https://www.shellcheck.net/)
[![Tests](https://img.shields.io/badge/tests-55%20passing-brightgreen)](tests/)

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
- **`ll`**: Colorful long listing with enhanced formatting
- **`dus`**: Disk usage script with sorting and coloring
- **`dusf`**: File-based disk usage analysis
- **`dusf.`**: Alternative disk usage format

### ✅ Quality Assurance
- **ShellCheck**: All scripts pass static analysis
- **BATS Tests**: 55 automated tests covering core functionality
- **CI/CD**: Automated testing on Linux and macOS
- **Pre-commit hooks**: Code quality checks before commit

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
sudo rm /usr/local/bin/ll /usr/local/bin/dus /usr/local/bin/dusf /usr/local/bin/dusf.
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
├── scripts/bin/          # Utility scripts (executables)
│   ├── ll              # Colorful long listing
│   ├── dus             # Disk usage script
│   ├── dusf            # File-based disk usage
│   └── dusf.            # Alternative disk usage
├── env/                 # Environment activation scripts
│   ├── activate.bash   # Bash activation
│   ├── activate.zsh    # Zsh activation
│   └── activate.fish   # Fish activation
├── install.sh           # Unified installation script
├── tests/                # BATS test suite
│   ├── alias.bats       # Tests for aliases.bash
│   ├── bash.bats        # Tests for prompt.bash and env.bash
│   ├── scripts_ll.bats  # Tests for ll script
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

# Testing
make test          # Run all tests (BATS + linting)
make test-bats     # Run only BATS tests

# Formatting
make format        # Format fish scripts

# Pre-commit hooks
make install-hooks # Install pre-commit hooks

# Cleanup
make clean         # Remove temporary files
```

### Running Tests

```bash
# Run all tests
make test-bats

# Run specific test file
bats tests/alias.bats

# Verbose output
bats -v tests/alias.bats
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

The project includes a comprehensive test suite with **55 tests** covering:
- Alias definitions and functionality
- Function definitions and behavior
- Script functionality and options
- Cross-platform compatibility

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
- Automated testing on Linux and macOS
- ShellCheck validation
- Fish syntax checking
- Test coverage reports

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
