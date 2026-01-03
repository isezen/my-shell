# Requirements

This document specifies the system requirements and dependencies for the my-shell project.

## Shell Requirements

### Required Shells

- **Bash**: 4.0 or later
  - Tested with: Bash 5.3.3
  - Required for: `alias.sh`, `bash.sh`, and utility scripts
  - Check version: `bash --version`

- **Fish Shell**: 4.0 or later
  - Tested with: Fish 4.3.2
  - Required for: `my_settings.fish` configuration
  - Check version: `fish --version`
  - Note: Fish 2.2+ was previously supported, but 4.0+ is now recommended

- **Zsh**: Supported (with bash compatibility)
  - Works with bash-compatible features
  - No specific minimum version requirement

### POSIX Compliance

All scripts aim for POSIX compliance where possible. Standard POSIX utilities are used:
- `ls`, `find`, `grep`, `sed`, `awk`, `cut`, `sort`, `wc`, `head`, `tail`
- `date`, `mkdir`, `cd`, `pwd`
- `curl`, `wget` (for installation scripts)

## Platform Requirements

### Supported Operating Systems

- **macOS**: macOS 10.13 (High Sierra) or later
  - Tested on: macOS 13.6 (Darwin 23.6.0)
  - ARM64 (Apple Silicon) and x86_64 (Intel) supported

- **Linux**: Modern Linux distributions
  - **Ubuntu**: 18.04 LTS or later
  - **Debian**: 10 (Buster) or later
  - **Fedora**: 30 or later
  - Other distributions with POSIX-compliant utilities should work

### Platform-Specific Notes

- **macOS**: Uses `vm_stat` for memory information, `system_profiler` for hardware info
- **Linux**: Uses `free` command for memory information, `lsb_release` for distribution info
- Scripts automatically detect the platform and use appropriate commands

## Required Dependencies

### Core Dependencies

These are required for basic functionality:

- **curl** or **wget**: For installation scripts
  - Usually pre-installed on most systems
  - Used in: `install_shell_settings.sh`, `install_shell_scripts.sh`

- **Git**: For cloning the repository (development)
  - Minimum: Git 2.0+
  - Tested with: Git 2.52.0

### System Utilities

Standard POSIX utilities (usually pre-installed):
- `ls`, `find`, `grep`, `sed`, `awk`, `cut`, `sort`
- `date`, `mkdir`, `cd`, `pwd`, `echo`, `printf`
- `wc`, `head`, `tail`, `xargs`
- `netstat` or `ss` (for network port listing)
- `perl` (for macOS memory display fallback)

## Optional Dependencies

These enhance functionality but are not required:

### Enhanced Tools

- **ncdu**: Interactive disk usage analyzer
  - Used by: `du2` alias/function
  - Install: `brew install ncdu` (macOS) or `sudo apt-get install ncdu` (Linux)

- **htop**: Enhanced process viewer
  - Used by: `top` alias (if available)
  - Install: `brew install htop` (macOS) or `sudo apt-get install htop` (Linux)

- **grc**: Generic Colorizer
  - Used by: `ping`, `ps`, `head`, `tail` functions (if available)
  - Install: `brew install grc` (macOS) or see [grc documentation](https://github.com/garabik/grc)

- **dfc**: Colorized disk free command
  - Used by: `df` alias (if available)
  - Install: `brew install dfc` (macOS) or `sudo apt-get install dfc` (Linux)

- **mogrify** (ImageMagick): Image manipulation
  - Used by: `webify` alias (if available)
  - Install: `brew install imagemagick` (macOS) or `sudo apt-get install imagemagick` (Linux)

- **fortune**: Fortune cookies
  - Used by: `fish_greeting` function (if available)
  - Install: `brew install fortune` (macOS) or `sudo apt-get install fortune` (Linux)

### Package Managers

- **MacPorts** (`port`): For macOS package management
  - Used by: `update` alias/function (if available)
  - Install: [MacPorts website](https://www.macports.org/)

- **apt-get**: For Debian/Ubuntu package management
  - Used by: `update` alias and `sagi` alias (if available)
  - Usually pre-installed on Debian/Ubuntu systems

## Development Dependencies

Required only for development and contributing:

### Code Quality Tools

- **ShellCheck**: 0.7.0 or later
  - Static analysis for shell scripts
  - Install: `brew install shellcheck` (macOS) or `sudo apt-get install shellcheck` (Linux)
  - Used by: `make lint-bash`, pre-commit hooks, CI/CD

- **Fish Shell**: 4.0 or later
  - For fish script syntax checking
  - Install: `brew install fish` (macOS) or `sudo apt-get install fish` (Linux)
  - Used by: `make lint-fish`, pre-commit hooks

### Testing Tools

- **BATS**: 1.0.0 or later
  - Tested with: BATS 1.13.0
  - Bash Automated Testing System
  - Install: `brew install bats-core` (macOS) or `sudo apt-get install bats` (Linux)
  - Used by: `make test-bats`, CI/CD

### Development Tools

- **pre-commit**: 2.0.0 or later (optional but recommended)
  - Git hooks framework
  - Install: `pip install pre-commit`
  - Used by: `make install-hooks`

- **make**: For running development commands
  - Usually pre-installed on Unix-like systems
  - Used by: `Makefile` targets

## Installation Requirements

### For End Users

Minimum requirements:
- One of: Bash 4.0+, Fish 4.0+, or Zsh
- `curl` or `wget`
- Internet connection (for one-liner installation)

### For Developers

Additional requirements:
- Git 2.0+
- ShellCheck 0.7.0+
- BATS 1.0.0+
- Fish 4.0+ (for fish script development)
- pre-commit 2.0.0+ (optional)

## Version Compatibility

### Backward Compatibility

- Scripts are designed to work with older versions where possible
- Some features may require newer versions (e.g., Fish 4.0+ for certain functions)
- POSIX compliance ensures maximum compatibility

### Testing

The project is tested on:
- **macOS**: 13.6 (Darwin 23.6.0) with Bash 5.3.3, Fish 4.3.2
- **Linux**: Ubuntu 20.04+ with Bash 5.0+, Fish 3.0+

## Checking Your System

### Check Shell Versions

```bash
# Bash version
bash --version

# Fish version
fish --version

# Zsh version
zsh --version
```

### Check Required Tools

```bash
# Check if curl is available
command -v curl

# Check if wget is available
command -v wget

# Check if Git is available
git --version
```

### Check Optional Tools

```bash
# Check optional tools
command -v ncdu && echo "ncdu: available" || echo "ncdu: not installed"
command -v htop && echo "htop: available" || echo "htop: not installed"
command -v grc && echo "grc: available" || echo "grc: not installed"
```

## Troubleshooting

### Common Issues

1. **"Command not found" errors**:
   - Ensure required tools are installed
   - Check your `PATH` environment variable
   - Some commands may be in `/usr/local/bin` or `/opt/local/bin`

2. **Fish version too old**:
   - Install Fish 4.0+ from your package manager
   - Or compile from source: [Fish Shell website](https://fishshell.com/)

3. **POSIX compatibility issues**:
   - Ensure you're using POSIX-compliant versions of utilities
   - On macOS, consider installing GNU coreutils: `brew install coreutils`

4. **Platform-specific commands**:
   - Scripts automatically detect the platform
   - If issues occur, check platform detection logic

## Additional Resources

- [Bash Documentation](https://www.gnu.org/software/bash/manual/)
- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [POSIX Specification](https://pubs.opengroup.org/onlinepubs/9699919799/)
- [ShellCheck Documentation](https://www.shellcheck.net/)
- [BATS Documentation](https://github.com/bats-core/bats-core)

