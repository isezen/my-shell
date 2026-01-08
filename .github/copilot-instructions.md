# AI Coding Agent Instructions for my-shell

## Project Overview

Cross-platform shell configuration system with utility scripts for bash, zsh, and fish. Supports Linux and macOS with environment activation similar to Python virtualenvs.

## Critical Architecture Patterns

### Multi-Shell Abstraction

**Shell-Specific Implementation Pattern**: Each shell has parallel implementations in `shell/{bash,fish,zsh}/`:
- `init.*` - Single entrypoint that sources other modules in order
- `aliases.*` - Functions and aliases (must stay synchronized via `shell/aliases.yml`)
- `prompt.*` - Shell-specific prompt customization
- `env.*` - Environment variables

**Alias Synchronization**: The `shell/aliases.yml` file is the source of truth. When adding/modifying aliases:
1. Update `shell/aliases.yml` first
2. Update all shell implementations (`*.bash`, `*.fish`, `*.zsh`)
3. Run `make alias-sync` to verify synchronization (CI will fail if out of sync)

Example from [shell/aliases.yml](shell/aliases.yml):
```yaml
- name: ll
  description: 'long list'
```

### Platform Dispatcher Pattern (`ll` wrapper)

The [scripts/bin/ll](scripts/bin/ll) wrapper uses **precedence-based dispatch**:
1. `LL_IMPL_PATH` - explicit path override (highest priority)
2. `LL_SCRIPT` - legacy override with recursion guard
3. `LL_IMPL=linux|macos` - force specific implementation
4. Auto-detect via `uname -s` (Darwin → `ll_macos`, else → `ll_linux`)

**Exit codes matter**: Return `1` for missing executables, `2` for invalid `LL_IMPL` values.

Platform implementations:
- [scripts/bin/ll_macos](scripts/bin/ll_macos) - BSD userland (macOS)
- [scripts/bin/ll_linux](scripts/bin/ll_linux) - GNU coreutils (Linux)

**Known trap**: macOS implementation uses ASCII US (0x1F) as internal delimiter, never tab (tab can appear in filenames).

**Implementation internals** ([scripts/bin/ll_macos](scripts/bin/ll_macos), [scripts/bin/ll_linux](scripts/bin/ll_linux)):
- Parse `stat` output for file metadata (permissions, size, mtime, owner/group)
- Apply relative time buckets ("2 days ago", "3 months ago") for human-readable dates
- Color-code by file type (directories, executables, symlinks) using ANSI escape sequences
- Quote filenames with spaces/tabs using `quote_if_needed()` function
- Handle symlinks with `->` arrow notation
- **Critical**: `ll_linux` and `ll_macos` outputs must be identical for cross-platform compatibility

**Output parity verification**: Use comparison tools to ensure implementations match:
- `scripts/dev/ls-compare` - Compare script output against canonical `ls -l`
- `scripts/dev/ll-compare` - Compare two implementations (e.g., `ll_linux` vs `ll_macos`)
- Set `LL_NOW_EPOCH` for deterministic timestamp comparisons
- Use `LL_CHATGPT_FAST=1` to skip slow tests during development

### Environment Activation System

Global switcher: [env/activate](env/activate) detects current shell and spawns new session with environment activated.

Shell-specific activators: `env/activate.{bash,zsh,fish}` modify PATH and source `shell/{shell}/init.{shell}`.

**Key functions**:
- `deactivate` - Restore original environment
- `reactivate` - Reload shell configs without deactivating (preserves prompt prefix)

## Development Workflows

### Test Coverage Expectations

**Baseline**: Maintain minimum 55 tests as documented in [tests/TEST_COVERAGE.md](tests/TEST_COVERAGE.md).

**Coverage tracking**:
- Total test count in [README.md](README.md) badge must stay current
- Breaking tests is unacceptable - all tests must pass before merge
- New features require corresponding test coverage
- Update [tests/TEST_COVERAGE.md](tests/TEST_COVERAGE.md) when adding test files

### Testing Strategy

**Platform-Aware Tests**: Use `make test-ll` for automatic platform detection:
- macOS: runs `test-ll-common` + `test-ll-macos`
- Linux: runs `test-ll-common` + `test-ll-linux`

**Test organization**:
- `tests/ll/*.bats` - Platform-independent wrapper tests (uses stub implementations)
- `tests/ll_macos/*.bats` - BSD-specific tests with harness in `00_harness.bash`
- `tests/ll_linux/*.bats` - GNU-specific tests with harness

**CI Constraint**: Test reports in [.github/workflows/ci.yml](.github/workflows/ci.yml) must read `.ci-test-ll.log` from `make test-ll` output, never run `bats` directly in report steps.

Example test pattern from [tests/ll/10_wrapper_stub.bats](tests/ll/10_wrapper_stub.bats):
```bash
setup() {
  SANDBOX_DIR="${BATS_TEST_TMPDIR}/ll-wrapper-sandbox"
  mkdir -p "${SANDBOX_DIR}"
  cp "${BATS_TEST_DIRNAME}/../../scripts/bin/ll" "${SANDBOX_DIR}/ll"
  # Create stubs for isolated testing
}
```

### Code Quality

**Required checks before commit**:
```bash
make lint           # ShellCheck + fish syntax
make alias-sync     # Verify alias synchronization
make test          # All tests + linting
```

**ShellCheck compliance**: All scripts must pass ShellCheck. Use `scripts/dev/run-shellcheck` for project-wide checks.

**Fish formatting**: Use `make format-fish` to auto-format with `fish_indent`.

**Pre-commit hooks**: Install with `make install-hooks` or `pre-commit install`.

Configured hooks in [.pre-commit-config.yaml](.pre-commit-config.yaml):
- ShellCheck via `scripts/dev/run-shellcheck` (severity=warning)
- Fish syntax check with `fish -n`
- Fish formatter with `fish_indent` (optional, can be enabled)
- Standard checks: trailing whitespace, YAML validation, merge conflicts

### Installation Modes

[install.sh](install.sh) supports multiple modes:
- `--local` - Install from local repo clone
- `--settings-only` - Shell configs only (no utility scripts)
- `--scripts-only` - Utility scripts only (no shell configs)
- `--user` - Install scripts to `~/.local/bin` (no sudo)
- `--dry-run=PATH` - Sandbox mode for testing (requires `-y` flag)

**BIN_PREFIX precedence**: `--bin-prefix` > `MY_SHELL_BIN_PREFIX` env var > `--user` flag > default `/usr/local/bin`

## Project-Specific Conventions

### Portability Requirements

- Use POSIX-compliant utilities where possible
- Platform detection via `uname -s` (Darwin vs Linux)
- Prefer `command -v` over `which` for command existence checks
- Function helper pattern: `__my_shell_has cmd` for existence checks

### Best-Effort Fish→Bash Porting

When porting from fish to bash/zsh, maintain functional parity but acknowledge limitations. Example from [shell/bash/aliases.bash](shell/bash/aliases.bash):
```bash
# ls wrapper (keeps original behavior, best-effort)
if __my_shell_has ls && __my_shell_has getopt; then
  ls() {
    local param=()
    if command ls --version >/dev/null 2>&1; then
      param+=(--color --group-directories-first)  # GNU ls only
    fi
    # Detect ls -l and dispatch to ll if available
  }
fi
```

### Documentation Standards

- Keep [README.md](README.md) badges updated (CI status, test count)
- Document new aliases in `shell/aliases.yml` with descriptions
- Update [REQUIREMENTS.md](REQUIREMENTS.md) if adding dependencies
- Test coverage tracked in [tests/TEST_COVERAGE.md](tests/TEST_COVERAGE.md)

**CHANGELOG.md process**: Follow [Keep a Changelog](https://keepachangelog.com/) format.
- Add entries to `[Unreleased]` section after each important modification
- Describe behavior changes, affected areas (e.g., "areas: wrapper/tests")
- Note if change is docs-only, refactor-only, or behavior-changing
- Example: `"Commit N: <description> (areas: <components>). Behavior change: <details>"`
- No version bump process currently - all changes accumulate in Unreleased

## Common Tasks

**Add new alias**: Edit `shell/aliases.yml`, then update `shell/{bash,fish,zsh}/aliases.*`, verify with `make alias-sync`

**Add new test**: Create `.bats` file in appropriate `tests/` subdirectory, follow existing patterns with `setup()` and `@test` blocks

**Fix ShellCheck issue**: Run `scripts/dev/run-shellcheck` to see all issues, fix with proper quoting and shellcheck directives

**Test on opposite platform**: Use `LL_IMPL=linux` or `LL_IMPL=macos` to force implementation, or run in CI via `make test-act` (requires Docker)

**Debug wrapper dispatch**: The wrapper outputs selector info to stderr on errors (e.g., "selector=LL_IMPL target not executable")

**Verify ll output parity**: Run `scripts/dev/ll-compare ll_linux ll_macos` to ensure cross-platform compatibility

**Compare against ls**: Run `scripts/dev/ls-compare ll_macos` to validate output format against canonical `ls -l`

**Update CONTRIBUTING.md**: When core development workflows change (new test targets, build commands, or development tools), update [CONTRIBUTING.md](CONTRIBUTING.md)

**Update README.md**: When core functionality changes (new features, aliases, or user-facing behavior), update [README.md](README.md) and badges

**Update CHANGELOG.md**: After each important modification, add entry to [CHANGELOG.md](CHANGELOG.md) `[Unreleased]` section with description and affected areas
