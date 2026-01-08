# Project Summary: my-shell

## Project Overview

### Purpose

my-shell is a collection of shell environment settings, aliases, and utility scripts designed to enhance productivity on both Linux and macOS. The project provides a unified, cross-platform shell configuration system that works with Bash, Zsh, and Fish shells.

### Scope

The project includes:

- **Shell Configuration**: Modular shell-specific configurations for Bash, Zsh, and Fish
  - Aliases and functions for common operations
  - Enhanced prompts with git integration
  - Environment variable management
  - History management utilities

- **Utility Scripts**: Cross-platform command-line tools
  - `ll`: Colorful long listing with enhanced formatting (platform-specific implementations)
  - `dus`: Disk usage analysis with sorting and coloring
  - `dusf`: File-based disk usage analysis
  - `dusf.`: Alternative disk usage format

- **Environment Activation System**: Virtual environment-like activation for development
  - Shell switching capabilities
  - PATH management
  - Configuration reloading

- **Testing Infrastructure**: Comprehensive BATS test suite
  - 55+ automated tests
  - Platform-specific test suites
  - Wrapper contract tests

### Platform Support

- **Operating Systems**:
  - macOS 10.13+ (High Sierra or later)
  - Linux (Ubuntu 18.04+, Debian 10+, Fedora 30+)
  - ARM64 (Apple Silicon) and x86_64 architectures

- **Shells**:
  - Bash 4.0+
  - Fish 4.0+
  - Zsh (with bash compatibility)

### Dependency Strategy

- **Core Dependencies**: POSIX-compliant utilities (usually pre-installed)
  - Standard Unix tools: `ls`, `find`, `grep`, `sed`, `awk`, `date`, etc.
  - `curl` or `wget` for installation

- **Development Dependencies**:
  - ShellCheck 0.7.0+ for static analysis
  - BATS 1.0.0+ for testing
  - pre-commit 2.0.0+ (optional) for git hooks

- **Optional Enhancements**:
  - `ncdu`, `htop`, `grc`, `dfc` for enhanced functionality
  - GNU coreutils on macOS (for `ll_linux` implementation)

- **Platform-Specific Tools**:
  - macOS: Uses BSD tools (`/bin/ls`, `/usr/bin/stat`, `/usr/bin/awk`)
  - Linux: Uses GNU tools (`ls --time-style`, `gawk`)

### Main Use Cases

1. **Daily Shell Usage**: Enhanced aliases and functions for file operations, navigation, system information
2. **Development Environment**: Activation system for isolated development testing
3. **Cross-Platform Development**: Consistent shell experience across macOS and Linux
4. **Script Development**: Utility scripts for common tasks (disk usage, file listing)

### Key Features

- **Modular Architecture**: Shell configurations split into logical modules (init, aliases, prompt, env)
- **Platform-Aware Implementations**: Separate `ll_linux` and `ll_macos` implementations for optimal platform support
- **Comprehensive Testing**: BATS test suite with platform-specific test harnesses
- **Quality Assurance**: ShellCheck validation, pre-commit hooks, CI/CD integration
- **Easy Installation**: One-liner installation script with multiple options
- **Environment Activation**: Virtual environment-like activation for development

## Architecture Overview

### Layered Architecture

The project follows a layered architecture organized by functionality:

1. **Shell Configuration Layer** (`shell/`):
   - Shell-specific configurations (bash, zsh, fish)
   - Modular structure: `init.*`, `aliases.*`, `prompt.*`, `env.*`
   - Single entrypoint pattern via `init.*` files

2. **Utility Scripts Layer** (`scripts/bin/`):
   - Executable command-line utilities
   - Platform-specific implementations where needed (`ll_linux`, `ll_macos`)
   - Thin wrapper pattern for platform dispatch (`ll`)

3. **Environment Activation Layer** (`env/`):
   - Shell activation scripts
   - PATH management
   - Configuration loading orchestration

4. **Testing Layer** (`tests/`):
   - Platform-specific test suites (`tests/ll_linux/`, `tests/ll_macos/`)
   - Common wrapper tests (`tests/ll/`)
   - Test harnesses with preflight checks

5. **Development Tools Layer** (`scripts/dev/`):
   - Development utilities (comparison tools, performance benchmarks)
   - Canonicalization scripts for testing

### Design Patterns

1. **Thin Wrapper Pattern** (`scripts/bin/ll`):
   - Platform detection and dispatch
   - No business logic in wrapper
   - Environment variable overrides for testing

2. **Single Entrypoint Pattern** (`shell/*/init.*`):
   - Each shell has one entrypoint file
   - Entrypoint sources other modules in correct order
   - Simplifies activation and maintenance

3. **Platform-Specific Implementation Pattern**:
   - Separate implementations for platform-specific features
   - Shared interface/contract via wrapper
   - Platform-aware test suites

4. **Soft-Skip Pattern** (test harnesses):
   - Preflight checks for required tools
   - Warning + skip (not failure) for missing dependencies
   - Enables cross-platform test execution

### Architectural Principles

1. **POSIX Compliance**: Scripts aim for POSIX compliance where possible
2. **Cross-Platform Compatibility**: Automatic platform detection and appropriate tool selection
3. **Modularity**: Clear separation of concerns (aliases, prompts, environment)
4. **Testability**: Comprehensive test coverage with platform-specific suites
5. **Quality First**: ShellCheck validation, pre-commit hooks, CI/CD integration
6. **User Experience**: Easy installation, clear documentation, helpful error messages

### Dependency Flow

```
User Shell (bash/zsh/fish)
    ↓
env/activate.* (activation)
    ↓
shell/*/init.* (entrypoint)
    ↓
shell/*/{aliases,prompt,env}.* (modules)
    ↓
scripts/bin/* (utilities)
    ↓
Platform-specific tools (GNU/BSD)
```

### Key Architectural Features

- **Platform Abstraction**: Wrapper pattern hides platform differences
- **Modular Configuration**: Shell configs split into logical, reusable modules
- **Test-Driven Development**: Platform-specific test suites ensure correctness
- **Development Environment**: Activation system enables isolated testing
- **Quality Gates**: Multiple quality checks (ShellCheck, tests, CI/CD)

## Module Catalog

### Shell Configuration Modules

#### `shell/bash/init.bash`

**Purpose**: Bash initialization entrypoint that sources all bash configuration modules in the correct order.

**Layer**: Shell Configuration Layer

**Dependencies**: 
- `shell/bash/aliases.bash`
- `shell/bash/prompt.bash`
- `shell/bash/env.bash`

**Exports**: All aliases, functions, and environment variables defined in dependent modules.

**Functions**: None (sourcing script)

---

#### `shell/bash/aliases.bash`

**Purpose**: Defines bash aliases and functions for file operations, navigation, system information, history management, and time utilities.

**Layer**: Shell Configuration Layer

**Dependencies**: Standard POSIX utilities

**Exports**: 
- Aliases: `ls`, `la`, `lf`, `ld`, `cdh`, `.1`, `.2`, `..`, `...`, `h`, `hg`, `now`, `nowtime`, `nowdate`, `mem`, `myip`, `du`, `du.`, `du2`, `ports`
- Functions: `hs` (history statistics), `fhere`, `FindFiles`

**Key Features**:
- Enhanced `ls` with colorization and directory-first sorting
- Quick navigation shortcuts
- History search and statistics
- System information utilities
- Platform-aware implementations (macOS vs Linux)

---

#### `shell/bash/prompt.bash`

**Purpose**: Configures bash prompt with colors, git integration, and directory display.

**Layer**: Shell Configuration Layer

**Dependencies**: Git (optional, for git prompt features)

**Exports**: `PS1` environment variable

**Features**:
- Colorized prompt
- Git branch display
- Current directory display
- Customizable colors

---

#### `shell/bash/env.bash`

**Purpose**: Sets bash environment variables, history configuration, and shell options.

**Layer**: Shell Configuration Layer

**Dependencies**: None

**Exports**: Environment variables for history, locale, shell options

**Features**:
- History size and format configuration
- Locale settings
- Shell option settings (e.g., `histappend`)

---

#### `shell/fish/init.fish`

**Purpose**: Fish shell initialization entrypoint that sources all fish configuration modules.

**Layer**: Shell Configuration Layer

**Dependencies**:
- `shell/fish/aliases.fish`
- `shell/fish/prompt.fish`
- `shell/fish/env.fish`

**Exports**: All fish functions and environment variables

---

#### `shell/fish/aliases.fish`

**Purpose**: Defines fish functions (fish doesn't support aliases the same way) for file operations, navigation, and system utilities.

**Layer**: Shell Configuration Layer

**Dependencies**: Standard POSIX utilities

**Exports**: Fish functions equivalent to bash aliases

**Note**: Fish uses functions instead of aliases, so all "aliases" are implemented as functions.

---

#### `shell/fish/prompt.fish`

**Purpose**: Configures fish prompt with colors, git integration, and directory display.

**Layer**: Shell Configuration Layer

**Dependencies**: Git (optional)

**Exports**: Fish `fish_prompt` function

**Features**:
- Colorized prompt with git branch
- Directory colors support
- Customizable appearance

---

#### `shell/fish/env.fish`

**Purpose**: Sets fish environment variables and shell configuration.

**Layer**: Shell Configuration Layer

**Dependencies**: None

**Exports**: Environment variables for fish shell

---

#### `shell/zsh/init.zsh`

**Purpose**: Zsh initialization entrypoint that sources all zsh configuration modules.

**Layer**: Shell Configuration Layer

**Dependencies**:
- `shell/zsh/aliases.zsh`
- `shell/zsh/prompt.zsh`
- `shell/zsh/env.zsh`

**Exports**: All zsh aliases, functions, and environment variables

---

#### `shell/zsh/aliases.zsh`

**Purpose**: Defines zsh aliases and functions compatible with bash aliases.

**Layer**: Shell Configuration Layer

**Dependencies**: Standard POSIX utilities

**Exports**: Zsh aliases and functions

---

#### `shell/zsh/prompt.zsh`

**Purpose**: Configures zsh prompt with colors and git integration.

**Layer**: Shell Configuration Layer

**Dependencies**: Git (optional)

**Exports**: Zsh prompt configuration

---

#### `shell/zsh/env.zsh`

**Purpose**: Sets zsh environment variables and shell options.

**Layer**: Shell Configuration Layer

**Dependencies**: None

**Exports**: Zsh environment variables

---

### Utility Scripts

#### `scripts/bin/ll`

**Purpose**: Thin wrapper that dispatches to platform-specific `ll` implementation based on OS detection or environment variables.

**Layer**: Utility Scripts Layer

**Dependencies**: 
- `scripts/bin/ll_linux` (Linux implementation)
- `scripts/bin/ll_macos` (macOS implementation)

**Exports**: Command-line interface for colorful long listing

**Dispatch Logic**:
1. `LL_IMPL_PATH` (highest priority - direct path override)
2. `LL_SCRIPT` (legacy alias, with recursion guard)
3. `LL_IMPL` (explicit: `linux` or `macos`)
4. OS detection (`uname -s`): Darwin → `ll_macos`, otherwise → `ll_linux`

**Exit Codes**:
- `1`: Missing or non-executable implementation
- `2`: Invalid `LL_IMPL` value

**Behavior**: Forwards all arguments verbatim to selected implementation.

---

#### `scripts/bin/ll_linux`

**Purpose**: GNU toolchain-based implementation of colorful long listing for Linux systems.

**Layer**: Utility Scripts Layer

**Dependencies**: 
- GNU `ls` with `--time-style=+%s` support
- GNU `awk` (preferably `gawk`) for advanced features
- GNU `date` and `touch` for test fixtures (optional)

**Features**:
- Colorized output with time-based color buckets
- Relative time display (sec/min/hrs/day/mon/yr)
- Permission-based coloring
- Owner/group display with "you" substitution
- Size tier coloring
- Human-readable size support
- Block size display
- Numeric UID/GID support
- Directory listing with `-d` flag
- `--` sentinel support for tricky filenames

**Output Format**: Compatible with GNU `ls -l --time-style=+%s` canonicalization

---

#### `scripts/bin/ll_macos`

**Purpose**: BSD toolchain-based implementation of colorful long listing for macOS systems.

**Layer**: Utility Scripts Layer

**Dependencies**:
- `/bin/ls` (BSD ls)
- `/usr/bin/stat` (BSD stat)
- `/usr/bin/awk` (BSD awk)
- `/usr/bin/readlink` (for symlink targets)

**Features**:
- Colorized output matching `ll_linux` semantics
- Relative time buckets (same as `ll_linux`)
- Permission-based coloring
- Owner/group display with "you" substitution
- Size tier coloring
- Human-readable size support
- Block size display
- Numeric UID/GID support
- Directory listing with `-d` flag
- `--` sentinel support

**Internal Format**: Uses ASCII Unit Separator (0x1F) as delimiter to avoid conflicts with tab characters in filenames

**Output Format**: Canonically equivalent to `ll_linux` after normalization

---

#### `scripts/bin/dus`

**Purpose**: Disk usage script with sorting and coloring.

**Layer**: Utility Scripts Layer

**Dependencies**: Standard POSIX utilities (`du`, `sort`, `awk`)

**Features**:
- Directory size analysis
- Sorting options
- Colorized output
- File/directory filtering

---

#### `scripts/bin/dusf`

**Purpose**: File-based disk usage analysis.

**Layer**: Utility Scripts Layer

**Dependencies**: Standard POSIX utilities

**Features**: File-level disk usage reporting

---

#### `scripts/bin/dusf.`

**Purpose**: Alternative disk usage format.

**Layer**: Utility Scripts Layer

**Dependencies**: Standard POSIX utilities

**Features**: Alternative formatting for disk usage

---

### Environment Activation

#### `env/activate`

**Purpose**: Global shell switcher (Bash script) that spawns a new interactive shell of the specified type.

**Layer**: Environment Activation Layer

**Dependencies**: 
- `env/activate.bash`
- `env/activate.zsh`
- `env/activate.fish`

**Usage**: `./env/activate <shell>` where `<shell>` is `bash`, `zsh`, or `fish`

**Behavior**: Spawns new interactive shell with activation applied

---

#### `env/activate.bash`

**Purpose**: Bash environment activation script that modifies PATH and sources bash configuration.

**Layer**: Environment Activation Layer

**Dependencies**: 
- `shell/bash/init.bash`
- `colortable.sh`

**Behavior**:
1. Sets `MY_SHELL_ROOT` to project root
2. Prevents double activation
3. Saves original PATH
4. Prepends `scripts/bin/` to PATH
5. Sources `shell/bash/init.bash`
6. Defines `colortable` alias
7. Adds `(my-shell)` prefix to prompt

**Exports**: 
- `MY_SHELL_ROOT`
- `MY_SHELL_ACTIVATED`
- `MY_SHELL_ACTIVATION_MODE`
- `MY_SHELL_OLD_PATH`
- `deactivate` function
- `reactivate` function

---

#### `env/activate.zsh`

**Purpose**: Zsh environment activation script (similar to bash version).

**Layer**: Environment Activation Layer

**Dependencies**: 
- `shell/zsh/init.zsh`
- `colortable.sh`

**Behavior**: Same as `activate.bash` but for zsh

---

#### `env/activate.fish`

**Purpose**: Fish environment activation script (similar to bash version).

**Layer**: Environment Activation Layer

**Dependencies**: 
- `shell/fish/init.fish`
- `colortable.sh`

**Behavior**: Same as `activate.bash` but for fish (uses fish-specific syntax)

---

### Installation

#### `install.sh`

**Purpose**: Unified installation script that installs both shell settings and utility scripts.

**Layer**: Installation Layer

**Dependencies**: `curl` or `wget`

**Features**:
- Automatic shell detection
- Automatic OS detection
- Interactive overwrite prompts
- Options: `--settings-only`, `--scripts-only`, `--local`, `--repo-root`, `-y/--yes`
- Environment variable overrides
- Bash 3.2 compatibility

**Installation Targets**:
- Shell settings: `~/.my-shell/<shell>/`
- Utility scripts: `/usr/local/bin` (or custom `BIN_PREFIX`)

---

### Test Infrastructure

#### `tests/ll/10_wrapper_stub.bats`

**Purpose**: Platform-independent wrapper contract tests using stub implementations.

**Layer**: Testing Layer

**Dependencies**: 
- `tests/ll/fixtures/ll_stub_impl.bash`
- `tests/test_helper/bats-assert/load.bash`
- `tests/test_helper/bats-support/load.bash`

**Tests**:
- `LL_IMPL_PATH` priority and argument forwarding
- `LL_IMPL` selection (linux/macos)
- `LL_SCRIPT` recursion guard
- Invalid `LL_IMPL` exit code (2)
- Non-executable path error handling

**Key Feature**: Uses stub executable to test wrapper behavior without platform dependencies

---

#### `tests/ll_linux/00_harness.bash`

**Purpose**: GNU toolchain test harness for `ll_linux` implementation tests.

**Layer**: Testing Layer

**Dependencies**: 
- GNU `ls` with `--time-style=+%s`
- GNU `awk` (preferably `gawk`)
- GNU `date` and `touch` (optional, for fixtures)

**Functions**:
- `ll_require_gnu_ls()`: Soft-skip if GNU ls unavailable
- `ll_require_gnu_awk()`: Soft-skip if gawk unavailable
- `ll_require_gnu_date()`: Soft-skip if GNU date unavailable
- `ll_require_gnu_touch()`: Soft-skip if GNU touch unavailable
- `ll_mk_testdir()`: Create temporary test directory
- `ll_rm_testdir()`: Cleanup test directory
- `ll_seed_fixtures_common()`: Create common test fixtures
- `ll_assert_canon_equal()`: Compare `ll` output with GNU `ls` canonicalized output

**Preflight**: `setup_file()` function checks for GNU ls on macOS and soft-skips if unavailable

---

#### `tests/ll_linux/10_core.bats`

**Purpose**: Core option matrix tests for `ll_linux` implementation.

**Layer**: Testing Layer

**Dependencies**: `tests/ll_linux/00_harness.bash`

**Tests**: 144 flag combinations covering:
- Directory variants (`-d`, `-d .`)
- Block size variants (`-s`)
- Human-readable variants (`-h`, `--si`)
- Numeric UID/GID variants (`-n`)
- Owner/group toggle variants (`-g`, `-G`, `-g -G`, `--no-group`)

**Additional Tests**: Alias sanity checks and permission combinations

---

#### `tests/ll_macos/00_harness.bash`

**Purpose**: BSD toolchain test harness for `ll_macos` implementation tests.

**Layer**: Testing Layer

**Dependencies**: 
- `/bin/ls` (BSD ls)
- `/usr/bin/awk` (BSD awk)
- `/usr/bin/stat` (BSD stat)

**Functions**:
- `ll_require_macos_userland()`: Soft-skip if not on macOS or required binaries missing
- `ll_mk_testdir()`: Create temporary test directory
- `ll_rm_testdir()`: Cleanup test directory
- `ll_seed_fixtures_common()`: Create common test fixtures using BSD tools
- `ll_macos_ref_generate()`: Generate reference output using BSD tools
- `ll_macos_assert_canon_equal()`: Compare `ll_macos` output with BSD reference

**Key Feature**: BSD-only reference generator (no GNU dependencies)

---

#### `tests/ll_macos/10_core.bats`

**Purpose**: Core tests for `ll_macos` implementation.

**Layer**: Testing Layer

**Dependencies**: `tests/ll_macos/00_harness.bash`

**Tests**:
- Preflight validation on Darwin
- Core parity tests (flag combinations)
- Tricky filename preservation
- Symlink arrow preservation
- Time bucket and color validation
- Permission and owner color validation
- Size tier color validation

---

### Development Tools

#### `scripts/dev/ll-compare`

**Purpose**: Cross-implementation comparison tool for `ll_linux` vs `ll_macos`.

**Layer**: Development Tools Layer

**Dependencies**: 
- `scripts/bin/ll_linux`
- `scripts/bin/ll_macos`
- `scripts/dev/ls-compare-canon-*.pl`

**Features**: 
- Deterministic comparison using `LL_NOW_EPOCH`
- Canonicalization for semantic equivalence
- Diff reporting

---

#### `scripts/dev/ls-compare`

**Purpose**: GNU ls baseline comparison tool.

**Layer**: Development Tools Layer

**Dependencies**: GNU `ls` with `--time-style=+%s`

**Features**: Compare script output with GNU ls baseline

---

#### `scripts/dev/ll-perf`

**Purpose**: Performance benchmarking tool for `ll` implementations.

**Layer**: Development Tools Layer

**Dependencies**: `hyperfine` or `time` command

**Features**: Benchmark `ll_linux` and `ll_macos` performance

---

## Data Flow

### Shell Configuration Loading

```
User starts shell
    ↓
RC file sources ~/.my-shell/<shell>/init.*
    ↓
init.* sources aliases.*, prompt.*, env.*
    ↓
Aliases/functions available in shell
```

### Environment Activation Flow

```
User runs: source env/activate.bash
    ↓
Activation script:
  1. Sets MY_SHELL_ROOT
  2. Checks for double activation
  3. Saves original PATH
  4. Prepends scripts/bin/ to PATH
  5. Sources shell/bash/init.bash
  6. Defines colortable alias
  7. Adds (my-shell) prompt prefix
    ↓
User has access to:
  - scripts/bin/* commands
  - All shell aliases/functions
  - Visual prompt indicator
```

### ll Command Execution Flow

```
User runs: ll -h /path
    ↓
scripts/bin/ll (wrapper):
  1. Checks LL_IMPL_PATH (highest priority)
  2. Checks LL_SCRIPT (with recursion guard)
  3. Checks LL_IMPL (linux|macos)
  4. Falls back to OS detection
    ↓
Selected implementation (ll_linux or ll_macos):
  1. Parses arguments
  2. Collects file metadata (GNU ls or BSD stat)
  3. Formats output with colors
  4. Prints to stdout
```

### Test Execution Flow

```
make test-ll
    ↓
OS detection (uname -s)
    ↓
Linux: make test-ll-common && make test-ll-linux
macOS: make test-ll-common && make test-ll-macos
    ↓
Each suite:
  1. Preflight checks (soft-skip if requirements missing)
  2. Run test fixtures
  3. Compare output with reference
  4. Report results
```

## Dependency Analysis

### Module Dependency Graph

```
install.sh
    ↓
env/activate.*
    ↓
shell/*/init.*
    ↓
shell/*/{aliases,prompt,env}.*
    ↓
scripts/bin/*
    ↓
Platform tools (GNU/BSD)
```

### Layer Violations

None identified. The architecture maintains clear layer separation:
- Shell configuration layer is independent
- Utility scripts layer depends only on platform tools
- Environment activation layer orchestrates loading
- Testing layer is isolated

### Circular Dependencies

None identified. All dependencies flow in one direction:
- Shell configs → utilities → platform tools
- Tests → implementations → platform tools
- Activation → shell configs

### External Dependencies

**Required**:
- POSIX utilities (pre-installed on most systems)
- `curl` or `wget` (for installation)

**Development**:
- ShellCheck (static analysis)
- BATS (testing)
- pre-commit (optional, git hooks)

**Platform-Specific**:
- Linux: GNU coreutils (ls, awk, date, touch)
- macOS: BSD tools (/bin/ls, /usr/bin/stat, /usr/bin/awk)

**Optional**:
- `ncdu`, `htop`, `grc`, `dfc` (enhanced functionality)
- GNU coreutils on macOS (for `ll_linux` testing)

## Architectural Decisions

### Decision 1: Platform-Specific Implementations for `ll`

**Decision**: Separate `ll_linux` and `ll_macos` implementations instead of a single unified implementation.

**Rationale**:
- GNU and BSD tools have different capabilities and syntax
- Platform-specific implementations can leverage native tools optimally
- Better performance by avoiding compatibility layers
- Clearer code without extensive platform conditionals

**Trade-offs**:
- ✅ Pros: Optimal performance, cleaner code, better maintainability
- ⚠️ Cons: Code duplication, requires separate testing

**Alternatives Considered**:
- Single unified implementation: Rejected due to complexity and performance concerns
- Compatibility layer: Rejected due to overhead and maintenance burden

**Known Limitations**:
- Requires maintaining two implementations
- Test coverage must be maintained for both platforms

**Future Considerations**:
- Potential unification if performance and complexity allow
- Decision documented in `wip/ll-decision.md`

---

### Decision 2: Thin Wrapper Pattern for Platform Dispatch

**Decision**: `scripts/bin/ll` is a thin wrapper that only handles dispatch, with no business logic.

**Rationale**:
- Clear separation of concerns
- Easy testing with stub implementations
- Flexible override mechanism for development
- Minimal overhead

**Trade-offs**:
- ✅ Pros: Simple, testable, flexible
- ⚠️ Cons: Extra indirection (minimal impact)

**Alternatives Considered**:
- Inline platform detection in each implementation: Rejected due to duplication
- Configuration file: Rejected due to complexity

---

### Decision 3: Modular Shell Configuration Structure

**Decision**: Split shell configurations into separate files (`init.*`, `aliases.*`, `prompt.*`, `env.*`) instead of monolithic files.

**Rationale**:
- Better organization and maintainability
- Easier to understand and modify
- Single entrypoint (`init.*`) simplifies activation
- Clear separation of concerns

**Trade-offs**:
- ✅ Pros: Maintainability, clarity, modularity
- ⚠️ Cons: More files to manage

**Alternatives Considered**:
- Monolithic files: Rejected due to maintainability concerns
- Per-feature files: Rejected due to excessive fragmentation

---

### Decision 4: Platform-Specific Test Suites

**Decision**: Separate test suites (`tests/ll_linux/`, `tests/ll_macos/`) with platform-specific harnesses.

**Rationale**:
- Each platform requires different tools (GNU vs BSD)
- Soft-skip pattern allows cross-platform test execution
- Clear test organization
- Platform-specific reference generators

**Trade-offs**:
- ✅ Pros: Accurate testing, clear organization, cross-platform compatibility
- ⚠️ Cons: Test suite duplication

**Alternatives Considered**:
- Single test suite with platform conditionals: Rejected due to complexity
- Platform-specific test execution only: Rejected due to development workflow needs

---

### Decision 5: ASCII Unit Separator for Internal Delimiters

**Decision**: Use ASCII Unit Separator (0x1F) instead of tab character for internal row delimiters in `ll_macos`.

**Rationale**:
- Test fixtures include filenames with literal tab characters (`a\tb.txt`)
- Tab delimiter would break parsing
- Unit Separator is safe (not used in filenames)

**Trade-offs**:
- ✅ Pros: Handles tricky filenames correctly
- ⚠️ Cons: Non-standard delimiter (documented)

**Alternatives Considered**:
- Tab delimiter: Rejected due to filename conflicts
- Newline delimiter: Rejected (newline filenames out of scope)

**Known Limitations**:
- Newline characters in filenames are explicitly out of scope

---

### Decision 6: Soft-Skip Pattern for Test Preflight

**Decision**: Test harnesses use warning + skip (not failure) when platform requirements are missing.

**Rationale**:
- Enables cross-platform development workflow
- Clear feedback about missing dependencies
- Tests don't fail on wrong platform (expected behavior)

**Trade-offs**:
- ✅ Pros: Better developer experience, cross-platform compatibility
- ⚠️ Cons: Requires careful test design

**Alternatives Considered**:
- Hard failure: Rejected due to workflow disruption
- Silent skip: Rejected due to lack of feedback

---

### Decision 7: Environment Activation System

**Decision**: Implement virtual environment-like activation system for development.

**Rationale**:
- Isolated development environment
- Easy testing across shells
- PATH management
- Visual feedback (prompt prefix)

**Trade-offs**:
- ✅ Pros: Better development workflow, shell switching, isolation
- ⚠️ Cons: Additional complexity

**Alternatives Considered**:
- Manual PATH setup: Rejected due to user friction
- Symlink installation: Rejected due to system modification requirements

---

### Decision 8: Unified Installer Script

**Decision**: Single `install.sh` script handles both shell settings and utility script installation.

**Rationale**:
- Simpler user experience
- Consistent installation process
- Flexible options (settings-only, scripts-only)
- Automatic detection (shell, OS)

**Trade-offs**:
- ✅ Pros: User experience, maintainability
- ⚠️ Cons: Larger script (manageable)

**Alternatives Considered**:
- Separate installers: Rejected due to user confusion
- Package manager: Rejected due to platform differences

---

## Summary

This project summary documents the my-shell project architecture, modules, and design decisions. The project follows a modular, layered architecture with clear separation between shell configurations, utility scripts, and testing infrastructure.

Key architectural strengths:
- Platform-aware implementations for optimal performance
- Comprehensive testing with platform-specific suites
- Modular shell configuration structure
- Quality assurance through ShellCheck and CI/CD

Areas for future enhancement:
- Complete Phase 3-9 items from plan-ll.md (ll_macos MVP, PATH control, performance benchmarks)
- Expand test coverage for edge cases
- Consider unification decision for ll implementations

