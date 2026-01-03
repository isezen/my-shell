# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Created `docs/IMPROVEMENTS.md` with comprehensive project improvement analysis
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
- Significantly expanded `README.md` with:
  - Features overview
  - Detailed installation instructions
  - Usage examples
  - Development guidelines
  - Project structure
  - Testing information
  - CI/CD information
- Created `REQUIREMENTS.md` with system requirements and dependencies documentation

### Changed
- Moved `IMPROVEMENTS.md` to `docs/` directory for better organization

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

