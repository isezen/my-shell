# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Created `CHANGELOG.md` to track project changes
- Added `.pre-commit-config.yaml` with ShellCheck and fish syntax checking hooks
- Added `Makefile` with convenient commands for linting, formatting, and testing
- Created `docs/SHELLCHECK_AND_PRE_COMMIT_EXPLANATION.md` with detailed explanations
- Added BATS (Bash Automated Testing System) test framework
- Created test suite in `tests/` directory with tests for:
  - `alias.sh` - Tests for aliases and functions (26 tests)
  - `bash.sh` - Tests for bash prompt settings (10 tests)
  - `scripts/ll` - Tests for colorful long listing script (11 tests)
  - `scripts/dus` - Tests for disk usage script (8 tests)
- Added `test-bats` Makefile target to run BATS tests
- Created `tests/README.md` with test documentation
- Created `tests/TEST_COVERAGE.md` with detailed test coverage documentation
- Added GitHub Actions CI/CD pipeline (`.github/workflows/ci.yml`)
- Created `CONTRIBUTING.md` with contribution guidelines
  - Introduced comprehensive CONTRIBUTING.md file outlining code of conduct, development workflow, coding standards, testing requirements, and pull request process
  - Included detailed instructions for setting up the development environment and making contributions
  - Established commit message guidelines to maintain consistency across contributions
- Significantly expanded `README.md` with:
  - Features overview
  - Detailed installation instructions
  - Usage examples
  - Development guidelines
  - Project structure
  - Testing information
  - CI/CD information
- Created `REQUIREMENTS.md` with system requirements and dependencies documentation
- Added environment activation system (`env/` directory):
  - `activate` - Global shell switcher (executable script)
  - `activate.bash` - Bash environment activation script
  - `activate.zsh` - Zsh environment activation script
  - `activate.fish` - Fish environment activation script
  - `reactivate` function - Reload environment files without deactivating
  - `deactivate` function - Cleanly deactivate environment
  - Features:
    - Automatic PATH management (adds `scripts/` directory)
    - Shell-specific configuration loading
    - Prompt indicator `(my-shell)` prefix
    - Shell switching support (switch between bash/zsh/fish)
    - Development-friendly: reload files with `reactivate` command
- Added Zsh support with new alias and prompt scripts:
  - Introduced `alias.zsh` and `zsh.zsh` files to provide Zsh-native aliases and prompt configurations
  - Enhanced prompt customization and history handling in Zsh to align with user expectations and Bash behavior
  - Improved prompt formatting in `zsh.zsh` to include brackets around the prompt character for better visibility
  - Enhanced prompt prefix rendering to use cyan color for better user experience

### Changed
- Updated documentation and enhanced project structure:
  - Added comprehensive GitHub Actions CI/CD pipeline for automated testing
  - Moved `IMPROVEMENTS.md` to the `docs/` directory for better organization
- Refactored script for improved readability and performance:
  - Corrected spelling errors in comments for clarity
  - Introduced size and time constants to enhance code maintainability
  - Refactored functions to use local variables and improved formatting for better readability
  - Optimized size and time calculations for performance improvements
  - Updated comments for better understanding of the code flow
- Refactored environment activation scripts for improved usability and functionality:
  - Enhanced the `activate`, `reactivate`, and `deactivate` functions across Bash, Zsh, and Fish scripts
  - Updated `CONTRIBUTING.md` to clarify the new activation options and usage instructions
  - Improved error handling and user feedback during activation and deactivation processes
  - Removed global function saving in `my_settings.fish` to simplify function management
  - Added support for shell switching and temporary directory management during activation
- Enhanced shell detection and activation process in environment scripts:
  - Improved the detection of the current shell by utilizing the parent process command for better accuracy
  - Refactored activation logic to handle shell switching more effectively, ensuring that the user's interactive shell is properly activated
  - Added cleanup procedures in the `deactivate` function to manage temporary artifacts and session states
  - Enhanced user feedback during shell switching to improve the overall activation experience
- Updated activation messages in environment script for improved clarity
- Refactored shell detection logic in activation script for improved accuracy
- Enhanced environment activation scripts for improved user experience:
  - Updated prompt formatting in `bash.sh` to include a clear (my-shell) prefix
  - Refactored the `activate` scripts across Bash, Zsh, and Fish to ensure consistent spawning of new interactive shells during activation
  - Simplified the deactivation process by removing unnecessary shell switching logic and ensuring proper cleanup of temporary artifacts
  - Improved user feedback during activation and deactivation to enhance clarity and usability
- Refactored Zsh prompt configuration and activation script for improved clarity:
  - Simplified the activation logic in `activate.zsh` to source `zsh.zsh` directly and ensure consistent prompt prefixing

### Fixed
- Fixed critical ShellCheck error in `alias.sh:50`: Added missing quotes around variable in `[ -n "$gnuls" ]` check
- Fixed critical ShellCheck error in `alias.sh:187`: Converted `hs` alias to function (aliases can't use positional parameters)
- Fixed critical ShellCheck error in `alias.sh:229`: Converted `free` alias to function in else block (aliases can't use positional parameters)
- Fixed ShellCheck warnings: SC2164 (cd error handling), SC2016 (variable expansion), SC2155 (local assignment), SC2086 (quoting), SC2046 (word splitting), SC2003 (expr usage), SC2034 (unused variables), SC2323 (unnecessary parentheses), SC2033 (alias in external commands)
- Fixed ShellCheck warnings in `colortable.sh`: SC2046 (command substitution quoting), SC2059 (printf format string)
- Fixed ShellCheck warnings in `install_shell_settings.sh`: SC2016 (added ignore comment for fish syntax)
- Fixed ShellCheck warnings in `ll-performance.sh`: SC2034 (unused variables), SC2012 (ls to find), SC2004 (arithmetic variables)
- Fixed all ShellCheck style warnings: SC2004 (arithmetic variables in alias.sh and ll-performance.sh), SC2012 (ls to find), SC2059 (printf format), SC2262 (alias definition/usage), SC2139/SC2263/SC2032/SC2317 (added to .shellcheckrc as intentional behavior)
- Created `.shellcheckrc` to disable intentional warnings (SC2139, SC2262, SC2263, SC2032, SC2317)

