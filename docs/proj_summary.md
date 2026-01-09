# Project Summary: my-shell

This document provides a comprehensive summary of the project structure, modules, functions, and architectural decisions for shell script projects.

## Project Overview

### Purpose

A collection of shell environment settings, aliases, and utility scripts for bash and fish shells. Designed to work on both Linux and macOS.

### Scope

The project provides:
- Shell-specific configurations for Bash, Zsh, and Fish shells
- Environment activation system (similar to Python virtual environments)
- Utility scripts for file operations (`ll`, `dus`, `dusf`, `dusf.`)
- Comprehensive aliases and functions for file operations, system information, history management, and directory navigation
- Cross-platform support for Linux and macOS
- Automated testing suite with 55 BATS tests
- Code quality tools (ShellCheck, pre-commit hooks)

### Platform Support

- **Linux**: Ubuntu 18.04+, Debian 10+, Fedora 30+, and other modern distributions
- **macOS**: macOS 10.13 (High Sierra) or later, tested on macOS 13.6
- **Shells**: Bash 4.0+, Fish 4.0+, Zsh (with bash compatibility)
- **Architectures**: ARM64 (Apple Silicon) and x86_64 (Intel) supported

### Dependency Strategy

- **Core dependencies**: POSIX-compliant utilities (ls, find, grep, sed, awk, etc.)
- **Required tools**: curl or wget for installation
- **Optional enhancements**: ncdu, htop, grc, dfc, imagemagick, fortune
- **Development tools**: ShellCheck 0.7.0+, BATS 1.0.0+, Fish 4.0+ for development
- **No external package dependencies**: All scripts use standard system utilities

### Main Use Cases

1. **Shell Environment Setup**: Quick installation of shell configurations for Bash, Zsh, or Fish
2. **Development Environment**: Activate project-specific shell environment with utility scripts in PATH
3. **File Operations**: Enhanced `ls` and `ll` commands with colors and formatting
4. **System Information**: Quick access to memory usage, IP address, disk usage, and process information
5. **History Management**: Enhanced history commands with search and statistics
6. **Directory Navigation**: Shortcuts for quick directory navigation (`.1`, `.2`, `..`, `...`, etc.)
7. **Time Utilities**: Quick date/time commands (`now`, `nowtime`, `nowdate`)

### Key Features

- **Shell Aliases & Functions**: Enhanced file operations, system information, history management, and navigation shortcuts
- **Fish Shell Support**: Full fish shell configuration with colorful prompt and git integration
- **Utility Scripts**: `ll` (colorful long listing), `dus` (disk usage), `dusf` (file-based disk usage)
- **Quality Assurance**: ShellCheck validation, 55 BATS tests, CI/CD integration
- **Environment Activation System**: Virtual environment-like activation for shell environments
- **Cross-Platform**: Works on both Linux and macOS with automatic platform detection

## Architecture Overview

### Layered Architecture

The project follows a shell-specific layered architecture:

1. **Activation Layer** (`env/`): Environment activation scripts that set up the shell environment
   - `activate.bash`, `activate.zsh`, `activate.fish`: Shell-specific activators
   - Handles PATH modification, prompt customization, and environment variable management

2. **Initialization Layer** (`shell/*/init.*`): Entry points for shell-specific configurations
   - Sources all configuration components in the correct order
   - Provides single entry point for shell initialization

3. **Configuration Layer** (`shell/*/`): Shell-specific configuration modules
   - `aliases.*`: Aliases and utility functions
   - `prompt.*`: Prompt customization
   - `env.*`: Environment variable settings

4. **Utility Scripts Layer** (`scripts/bin/`): Executable utility scripts
   - `ll`: Colorful long listing
   - `dus`, `dusf`, `dusf.`: Disk usage utilities

### Design Patterns

- **Activation Pattern**: Similar to Python virtual environments, provides isolated shell environments
- **Single Entry Point**: Each shell uses a single `init.*` file that sources all components
- **Shell Abstraction**: Common functionality abstracted across Bash, Zsh, and Fish with shell-specific implementations
- **Best-Effort Portability**: Functions ported from Fish to Bash/Zsh with best-effort compatibility

### Architectural Principles

1. **Shell Compatibility**: Support for Bash, Zsh, and Fish with shell-specific implementations
2. **POSIX Compliance**: Where possible, scripts use POSIX-compliant utilities
3. **Platform Detection**: Automatic detection of Linux vs macOS with appropriate command usage
4. **Environment Isolation**: Activation system provides isolated environment with clean deactivation
5. **Modularity**: Configuration split into logical modules (aliases, prompt, env)
6. **Testability**: Comprehensive test suite with BATS covering core functionality

### Dependency Flow

1. **Activation Flow**:
   - User sources `env/activate.<shell>` or uses global switcher `env/activate`
   - Activator sets `MY_SHELL_ROOT` and modifies PATH
   - Activator sources `shell/<shell>/init.<shell>`
   - `init.*` sources `aliases.*`, `prompt.*`, and `env.*` in order
   - Prompt is customized with `(my-shell)` prefix

2. **Initialization Flow**:
   - `init.*` → `aliases.*` → `prompt.*` → `env.*`
   - Each module can depend on previous modules

3. **Deactivation Flow**:
   - `deactivate` function restores PATH, prompt, and environment variables
   - If shell was switched, returns to original shell

### Key Architectural Features

- **Environment Activation System**: Virtual environment-like system for shell environments with activation/deactivation
- **Shell Switching**: Ability to switch between Bash, Zsh, and Fish while maintaining environment
- **Prompt Customization**: Shell-specific prompt customization with `(my-shell)` prefix
- **Function Persistence**: In Fish exec-activation, functions persist in new interactive session using init files
- **PATH Management**: Snapshot and restore PATH for exact restoration during deactivation
- **Cross-Platform Support**: Automatic platform detection and appropriate command usage

## Module Catalog

This section catalogs all source modules organized by directory structure.

### 3.1 env/

#### 3.2 `env/activate.bash`

**Purpose**: Bash environment activation script. Provides activation system similar to Python virtual environments. Sets up PATH, sources shell configuration, and customizes prompt with `(my-shell)` prefix.
**Shell Type**: bash
**Layer**: Activation Layer

**Dependencies**: activate.bash, env/activate.bash, gawk, if, shell/bash/init.bash
**Aliases**: colortable


#### Functions

##### `reactivate()`

- **Purpose**: Reactivate function

##### `deactivate()`

- **Purpose**: Deactivate function

#### 3.3 `env/activate.fish`

**Purpose**: Fish environment activation script. Provides activation system similar to Python virtual environments. Sets up PATH, sources shell configuration, and customizes prompt with `(my-shell)` prefix using function copying strategy.
**Shell Type**: fish
**Layer**: Activation Layer

**Dependencies**: &&, activate.fish, env/activate.fish, gawk, if, shell/fish/init.fish

#### Functions

##### `colortable()`

- **Purpose**: Define colortable function (global scope)

##### `__my_shell_prompt_prefix()`

- **Purpose**: Define prompt prefix function (global scope)

##### `reactivate()`

- **Purpose**: Reactivate function (global scope)

##### `deactivate()`

- **Purpose**: Deactivate function (global scope)

#### 3.4 `env/activate.zsh`

**Purpose**: Zsh environment activation script. Provides activation system similar to Python virtual environments. Sets up PATH, sources shell configuration, and customizes prompt with `(my-shell)` prefix.
**Shell Type**: zsh
**Layer**: Activation Layer

**Dependencies**: activate.zsh, env/activate.zsh, gawk, if, shell/zsh/init.zsh
**Aliases**: colortable


#### Functions

##### `reactivate()`

- **Purpose**: Reactivate function

##### `deactivate()`

- **Purpose**: Deactivate function

### 3.5 shell/bash/

#### 3.6 `shell/bash/aliases.bash`

**Purpose**: Bash aliases and utility functions (best-effort port from fish). Provides file operations, system information, history management, directory navigation, and time utilities.
**Shell Type**: bash
**Layer**: Configuration Layer

**Dependencies**: -maxdepth, -name, -path, -type, awk, bc, find, grep, ll, ls, perl, profile/config, sed, ~/.bash_profile, ~/.bashrc, ...

#### Functions

##### `__my_shell_has()`

- **Purpose**: Check if a command exists in the system. Helper function for command availability checks.

##### `__get_os()`

- **Purpose**: *[To be documented]*

##### `cdh()`

- **Purpose**: ============================================================================

##### `j()`

- **Purpose**: Basic listing aliases

##### `l()`

- **Purpose**: list entries by columns

##### `la()`

- **Purpose**: list regular + hidden

##### `sl()`

- **Purpose**: typo correction for ls

##### `laf()`

- **Purpose**: list regular+hidden files

##### `ld()`

- **Purpose**: list regular directories

##### `lf()`

- **Purpose**: list regular files

##### `lh()`

- **Purpose**: list hidden items

##### `lhd()`

- **Purpose**: list hidden directories

##### `lhf()`

- **Purpose**: list hidden files

##### `lad()`

- **Purpose**: list all directories

##### `lla()`

- **Purpose**: long list all

##### `lld()`

- **Purpose**: long list regular directories

##### `llh()`

- **Purpose**: long list hidden

##### `llhd()`

- **Purpose**: long list hidden directories

##### `llf()`

- **Purpose**: long list regular files

##### `llad()`

- **Purpose**: long list all directories

##### `llaf()`

- **Purpose**: long list all files + hidden

##### `llhf()`

- **Purpose**: long list only hidden files

##### `FindFiles()`

- **Purpose**: ============================================================================

##### `fhere()`

- **Purpose**: find in current directory

##### `h()`

- **Purpose**: ============================================================================

##### `hc()`

- **Purpose**: history clear

##### `clhist()`

- **Purpose**: clear history

##### `hs()`

- **Purpose**: statistics of history

##### `now()`

- **Purpose**: current time

##### `nowtime()`

- **Purpose**: current time

##### `nowdate()`

- **Purpose**: current date

##### `showpath()`

- **Purpose**: show PATH

##### `psg()`

- **Purpose**: searchable process table

##### `pfind()`

- **Purpose**: find process

##### `mcd()`

- **Purpose**: ============================================================================

##### `mkd()`

- **Purpose**: mkdir with parent directories and verbose output

##### `mkdir()`

- **Purpose**: mkdir with parent directories

##### `sourceme()`

- **Purpose**: source profile/config

#### 3.7 `shell/bash/env.bash`

**Purpose**: Environment settings for bash shell. Contains environment variable configurations including history settings, dircolors, and other environment customizations.
**Shell Type**: bash
**Layer**: Configuration Layer

**Dependencies**: curl, dircolors, export, ls

#### 3.8 `shell/bash/init.bash`

**Purpose**: my-shell bash initialization entrypoint. Sources all bash configuration components (aliases, prompt, env) in the correct order.
**Shell Type**: bash
**Layer**: Initialization Layer

**Dependencies**: None

#### 3.9 `shell/bash/prompt.bash`

**Purpose**: Prompt configuration for bash shell. Provides shiny bash prompt support with date, time, user, host, and path information. Uses PROMPT_COMMAND to update path dynamically.
**Shell Type**: bash
**Layer**: Configuration Layer

**Dependencies**: #, Keep, PS1='\[\033[0, PS1='\h

#### Functions

##### `bash_prompt_command()`

- **Purpose**: Update prompt path dynamically before each prompt display. Called by PROMPT_COMMAND.

##### `bash_prompt()`

- **Purpose**: Set up bash prompt with date, time, user, host, and path information. Configures PROMPT_COMMAND to update path dynamically.

### 3.10 shell/fish/

#### 3.11 `shell/fish/aliases.fish`

**Purpose**: Fish aliases and utility functions. Provides file operations, system information, history management, directory navigation, and time utilities. Native Fish implementation.
**Shell Type**: fish
**Layer**: Configuration Layer

**Dependencies**: -maxdepth, -name, -type, \, awk, find, grep, ll, ls, perl, profile/config, sed, ~/.config/fish/config.fish

#### Functions

##### `__my_shell_has()`

- **Purpose**: !/usr/bin/env fish

##### `__get_os()`

- **Purpose**: Get OS

##### `cdh()`

- **Purpose**: ============================================================================

##### `j()`

- **Purpose**: Basic listing aliases

##### `ld()`

- **Purpose**: list regular directories

##### `lh()`

- **Purpose**: list hidden items

##### `lad()`

- **Purpose**: list all directories

##### `lla()`

- **Purpose**: Long listing functions

##### `fhere()`

- **Purpose**: find in current directory

##### `h()`

- **Purpose**: ============================================================================

##### `clhist()`

- **Purpose**: clear history

##### `now()`

- **Purpose**: current time

##### `psg()`

- **Purpose**: searchable process table

##### `mcd()`

- **Purpose**: ============================================================================

#### 3.12 `shell/fish/env.fish`

**Purpose**: Environment settings for fish shell. Contains environment variable configurations including dircolors and other environment customizations.
**Shell Type**: fish
**Layer**: Configuration Layer

**Dependencies**: ls, sed

#### Functions

##### `set_dircolors()`

- **Purpose**: set_dircolors function

#### 3.13 `shell/fish/init.fish`

**Purpose**: my-shell fish initialization entrypoint. Sources all fish configuration components (aliases, prompt, env) in the correct order.
**Shell Type**: fish
**Layer**: Initialization Layer

**Dependencies**: &&

#### 3.14 `shell/fish/prompt.fish`

**Purpose**: Prompt configuration for fish shell. Provides shiny fish prompt support with git integration and colorful output.
**Shell Type**: fish
**Layer**: Configuration Layer

**Dependencies**: -f

#### Functions

##### `fish_prompt()`

- **Purpose**: Fish shell prompt function. Provides colorful prompt with git integration and path display.

### 3.15 shell/zsh/

#### 3.16 `shell/zsh/aliases.zsh`

**Purpose**: Zsh aliases and utility functions (best-effort port from fish). Provides file operations, system information, history management, directory navigation, and time utilities.
**Shell Type**: zsh
**Layer**: Configuration Layer

**Dependencies**: #, -maxdepth, -name, -path, -type, awk, bc, find, grep, ll, ls, perl, profile/config, sed, ~/.zlogin, ...

#### Functions

##### `__my_shell_has()`

- **Purpose**: !/usr/bin/env zsh

##### `__get_os()`

- **Purpose**: *[To be documented]*

##### `cdh()`

- **Purpose**: ============================================================================

##### `j()`

- **Purpose**: Basic listing aliases

##### `l()`

- **Purpose**: list entries by columns

##### `la()`

- **Purpose**: list regular + hidden

##### `sl()`

- **Purpose**: typo correction for ls

##### `laf()`

- **Purpose**: Advanced listing functions

##### `ld()`

- **Purpose**: list regular directories

##### `lf()`

- **Purpose**: list regular files

##### `lh()`

- **Purpose**: list hidden items

##### `lhd()`

- **Purpose**: list hidden directories

##### `lhf()`

- **Purpose**: list hidden files

##### `lad()`

- **Purpose**: list all directories

##### `lla()`

- **Purpose**: Long listing functions

##### `lld()`

- **Purpose**: long list regular directories

##### `llh()`

- **Purpose**: long list hidden

##### `llhd()`

- **Purpose**: long list hidden directories

##### `llf()`

- **Purpose**: long list regular files

##### `llad()`

- **Purpose**: long list all directories

##### `llaf()`

- **Purpose**: long list all files + hidden

##### `llhf()`

- **Purpose**: long list only hidden files

##### `FindFiles()`

- **Purpose**: ============================================================================

##### `fhere()`

- **Purpose**: find in current directory

##### `h()`

- **Purpose**: ============================================================================

##### `hc()`

- **Purpose**: Zsh cannot "history --clear" like fish; emulate with fc builtin.

##### `clhist()`

- **Purpose**: clear history

##### `hs()`

- **Purpose**: statistics of history

##### `now()`

- **Purpose**: current time

##### `nowtime()`

- **Purpose**: current time

##### `nowdate()`

- **Purpose**: current date

##### `showpath()`

- **Purpose**: show PATH

##### `psg()`

- **Purpose**: searchable process table

##### `pfind()`

- **Purpose**: find process

##### `mcd()`

- **Purpose**: ============================================================================

##### `mkd()`

- **Purpose**: mkdir with parent directories and verbose output

##### `mkdir()`

- **Purpose**: mkdir with parent directories

##### `sourceme()`

- **Purpose**: source profile/config

#### 3.17 `shell/zsh/env.zsh`

**Purpose**: Environment settings for zsh shell. Contains environment variable configurations including history settings, dircolors, and other environment customizations.
**Shell Type**: zsh
**Layer**: Configuration Layer

**Dependencies**: curl, dircolors, ls

#### 3.18 `shell/zsh/init.zsh`

**Purpose**: my-shell zsh initialization entrypoint. Sources all zsh configuration components (aliases, prompt, env) in the correct order.
**Shell Type**: zsh
**Layer**: Initialization Layer

**Dependencies**: None

#### 3.19 `shell/zsh/prompt.zsh`

**Purpose**: Prompt configuration for zsh shell. Provides zsh prompt support using bash prompt strategy ported to Zsh (native). Uses prompt substitution to compute truncated path.
**Shell Type**: zsh
**Layer**: Configuration Layer

**Dependencies**: None

#### Functions

##### `__my_shell_zsh_prompt_command()`

- **Purpose**: Compute truncated path before each prompt (bash_prompt_command equivalent). Internal helper function for zsh prompt.

---

## Data Flow

### Activation Flow

1. **User triggers activation**:
   - Direct: `source env/activate.<shell>`
   - Global switcher: `./env/activate` or `./env/activate <shell>`

2. **Environment setup**:
   - `MY_SHELL_ROOT` is set to project root directory
   - PATH snapshot saved to `MY_SHELL_OLD_PATH`
   - `scripts/bin/` prepended to PATH

3. **Configuration loading**:
   - Activator sources `shell/<shell>/init.<shell>`
   - `init.*` sources `aliases.*`, `prompt.*`, and `env.*` in sequence
   - Each module loads its functions, aliases, and environment variables

4. **Prompt customization**:
   - Bash/Zsh: `PS1` modified with `(my-shell)` prefix, original stored in `MY_SHELL_OLD_PS1`
   - Fish: `fish_prompt` function copied to `__my_shell_old_fish_prompt`, new prompt calls prefix function

5. **Function definitions**:
   - `deactivate` and `reactivate` functions defined
   - `colortable` alias/function defined
   - `MY_SHELL_ACTIVATED=1` set

### Deactivation Flow

1. **User triggers deactivation**: `deactivate`

2. **Environment restoration**:
   - PATH restored from `MY_SHELL_OLD_PATH` snapshot
   - Prompt restored from `MY_SHELL_OLD_PS1` (Bash/Zsh) or function copy (Fish)
   - Environment variables unset

3. **Function cleanup**:
   - `deactivate` and `reactivate` functions removed
   - `colortable` removed
   - Fish: `__my_shell_old_fish_prompt` and `__my_shell_prompt_prefix` removed

4. **Shell switching** (if applicable):
   - If `MY_SHELL_SWITCHED_FROM` is set, return to original shell
   - If Fish exec-activation, exit Fish session

### Reactivation Flow

1. **User triggers reactivation**: `reactivate`

2. **Configuration reload**:
   - Re-source `shell/<shell>/init.<shell>`
   - All configuration modules reloaded
   - `colortable` redefined
   - Prompt prefix ensured

3. **No environment changes**:
   - PATH remains modified
   - Environment remains active
   - Only configuration files reloaded

---

## Dependency Analysis

Total modules analyzed: 15
Total unique dependencies: 41

### Module Dependencies

**Activation Layer**:
- `env/activate.*` → `shell/*/init.*` (sources initialization entrypoint)

**Initialization Layer**:
- `shell/*/init.*` → `shell/*/aliases.*` (sources aliases)
- `shell/*/init.*` → `shell/*/prompt.*` (sources prompt)
- `shell/*/init.*` → `shell/*/env.*` (sources environment)

**Configuration Layer**:
- Modules are independent but loaded in sequence: aliases → prompt → env
- `prompt.*` may depend on functions defined in `aliases.*`
- `env.*` may depend on functions defined in `aliases.*`

**Utility Scripts Layer**:
- Independent executables in `scripts/bin/`
- No dependencies on configuration modules
- Can be used standalone or within activated environment

### Layer Violations

No layer violations detected. The architecture maintains clear separation:
- Activation layer only depends on initialization layer
- Initialization layer only depends on configuration layer
- Configuration modules are independent within their layer
- Utility scripts are independent

### Circular Dependencies

No circular dependencies detected. Dependency flow is unidirectional:
- Activation → Initialization → Configuration
- No module depends on a module that depends on it

### External Dependencies

**System Utilities** (POSIX-compliant, usually pre-installed):
- `ls`, `find`, `grep`, `sed`, `awk`, `cut`, `sort`, `wc`, `head`, `tail`
- `date`, `mkdir`, `cd`, `pwd`, `echo`, `printf`
- `curl`, `wget` (for installation)

**Platform-Specific**:
- macOS: `vm_stat`, `system_profiler`
- Linux: `free`, `lsb_release`

**Optional Enhancements**:
- `ncdu`, `htop`, `grc`, `dfc`, `imagemagick`, `fortune`

**Development Tools**:
- ShellCheck 0.7.0+ (for linting)
- BATS 1.0.0+ (for testing)
- Fish 4.0+ (for fish script development)

---

## Architectural Decisions

### 1. Environment Activation System

**Decision**: Implement a virtual environment-like activation system for shell environments.

**Rationale**:
- Provides isolated environment for development
- Allows switching between shells while maintaining environment
- Enables clean deactivation and restoration
- Similar to Python virtual environments, familiar to developers

**Trade-offs**:
- ✅ Pros: Clean environment management, easy activation/deactivation, shell switching support
- ⚠️ Cons: Additional complexity, requires understanding of activation flow

**Alternatives Considered**:
- Direct sourcing: Simpler but no clean deactivation
- Symlink installation: Requires system-level changes, harder to uninstall

### 2. Shell-Specific Implementations

**Decision**: Maintain separate implementations for Bash, Zsh, and Fish rather than a single POSIX-compliant script.

**Rationale**:
- Each shell has unique features and syntax
- Fish has native functions and better error handling
- Bash/Zsh compatibility allows best-effort porting from Fish
- Shell-specific optimizations possible

**Trade-offs**:
- ✅ Pros: Better shell integration, native features, optimized for each shell
- ⚠️ Cons: Code duplication, maintenance overhead for three implementations

**Alternatives Considered**:
- Single POSIX script: Would lose shell-specific features and optimizations
- Shell detection at runtime: More complex, less efficient

### 3. Function Copying Strategy for Fish Prompt

**Decision**: Use function copying strategy for Fish prompt customization instead of modifying prompt string.

**Rationale**:
- Fish uses functions, not strings, for prompts
- Function copying preserves original prompt functionality
- Allows clean restoration during deactivation
- No orphaned functions after deactivation

**Trade-offs**:
- ✅ Pros: Clean restoration, preserves original functionality, no orphaned functions
- ⚠️ Cons: More complex than string modification (but necessary for Fish)

**Alternatives Considered**:
- String modification: Not applicable to Fish (uses functions)
- Global variable: Less clean, harder to restore

### 4. PATH Snapshot and Restoration

**Decision**: Snapshot PATH at activation and restore exactly during deactivation.

**Rationale**:
- Ensures exact restoration of PATH
- Prevents PATH pollution from activation
- Allows clean deactivation without side effects
- Discards any PATH changes made while active

**Trade-offs**:
- ✅ Pros: Clean restoration, no PATH pollution, predictable behavior
- ⚠️ Cons: PATH changes during activation are lost (by design)

**Alternatives Considered**:
- Append-only PATH: Simpler but allows PATH pollution
- Smart PATH management: More complex, may not restore exactly

### 5. Single Entry Point (init.*)

**Decision**: Use single entry point (`init.*`) that sources all configuration modules.

**Rationale**:
- Simplifies activation flow
- Ensures correct loading order
- Single point of control for configuration
- Easier to maintain and understand

**Trade-offs**:
- ✅ Pros: Simple activation, correct order, single point of control
- ⚠️ Cons: Less flexibility in loading order (but order is intentional)

**Alternatives Considered**:
- Direct sourcing in activator: More complex, harder to maintain order
- Multiple entry points: More flexible but harder to manage

### 6. Best-Effort Portability

**Decision**: Port Fish functions to Bash/Zsh with best-effort compatibility rather than full feature parity.

**Rationale**:
- Fish has superior features (native functions, better error handling)
- Some Fish features cannot be fully replicated in Bash/Zsh
- Better to have working subset than no port at all
- Allows gradual improvement

**Trade-offs**:
- ✅ Pros: Functionality available in all shells, gradual improvement possible
- ⚠️ Cons: Some features may not work identically, requires testing

**Alternatives Considered**:
- Full feature parity: Impossible due to shell differences
- No porting: Would limit functionality in Bash/Zsh

### 7. No Nested Activation Support

**Decision**: Do not support nested activation (activating within an already activated environment).

**Rationale**:
- Adds significant complexity
- Rare use case
- Activation-started Fish sessions are not nested activation
- Simpler to prevent than to support

**Trade-offs**:
- ✅ Pros: Simpler implementation, clearer behavior
- ⚠️ Cons: Cannot nest activations (rarely needed)

**Alternatives Considered**:
- Nested activation support: More complex, rarely needed
- Stack-based activation: Even more complex, not worth the effort

### 8. Exec-Activation for Fish via Global Switcher

**Decision**: Use `exec` to start Fish when activated via global switcher, with init file for function persistence.

**Rationale**:
- Global switcher is Bash script, cannot be sourced by Fish
- `exec` replaces current process with Fish
- Init file ensures functions persist in new interactive session
- Allows `deactivate` to work in exec-activated Fish session

**Trade-offs**:
- ✅ Pros: Works with global switcher, functions persist, `deactivate` available
- ⚠️ Cons: Process replacement (by design), requires init file management

**Alternatives Considered**:
- Subprocess Fish: Functions wouldn't persist, `deactivate` wouldn't work
- Fish-specific switcher: More complex, duplicate logic

---