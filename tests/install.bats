#!/usr/bin/env bats
# install.bats
# Extensive test suite for install.sh (local + remote, dry-run sandbox, precedence, idempotency, error paths)

load test_helper/bats-support/load
load test_helper/bats-assert/load

setup() {
  export TEST_TMP="$BATS_TEST_TMPDIR"
  export FIXTURES="$TEST_TMP/fixtures"
  export REPO="$FIXTURES/repo"
  export SANDBOX="$TEST_TMP/sandbox"
  export STUBBIN="$TEST_TMP/stubbin"

  mkdir -p "$FIXTURES" "$REPO" "$SANDBOX" "$STUBBIN"

  # Locate install.sh under test (assumes install.bats is under tests/ or similar)
  # Use BATS_TEST_DIRNAME to resolve relative repo root robustly.
  local candidate1="$BATS_TEST_DIRNAME/../install.sh"
  local candidate2="$BATS_TEST_DIRNAME/../../install.sh"
  if [ -f "$candidate1" ]; then
    export INSTALL_SH_REAL="$candidate1"
  elif [ -f "$candidate2" ]; then
    export INSTALL_SH_REAL="$candidate2"
  else
    # Fallback: require INSTALL_SH env provided by caller
    if [ -z "${INSTALL_SH:-}" ] || [ ! -f "$INSTALL_SH" ]; then
      echo "install.sh not found. Set INSTALL_SH=/absolute/path/to/install.sh" >&2
      return 1
    fi
    export INSTALL_SH_REAL="$INSTALL_SH"
  fi

  # Copy install.sh into fixture repo root (so --local without --repo-root works)
  cp "$INSTALL_SH_REAL" "$REPO/install.sh"
  chmod +x "$REPO/install.sh"

  # Minimal repo layout expected by installer
  mkdir -p \
    "$REPO/shell/bash" "$REPO/shell/zsh" "$REPO/shell/fish" \
    "$REPO/scripts/bin"

  # Create minimal shell config files
  printf 'bash-init\n'   > "$REPO/shell/bash/init.bash"
  printf 'bash-alias\n'  > "$REPO/shell/bash/aliases.bash"
  printf 'bash-prompt\n' > "$REPO/shell/bash/prompt.bash"
  printf 'bash-env\n'    > "$REPO/shell/bash/env.bash"

  printf 'zsh-init\n'   > "$REPO/shell/zsh/init.zsh"
  printf 'zsh-alias\n'  > "$REPO/shell/zsh/aliases.zsh"
  printf 'zsh-prompt\n' > "$REPO/shell/zsh/prompt.zsh"
  printf 'zsh-env\n'    > "$REPO/shell/zsh/env.zsh"

  printf 'fish-init\n'   > "$REPO/shell/fish/init.fish"
  printf 'fish-alias\n'  > "$REPO/shell/fish/aliases.fish"
  printf 'fish-prompt\n' > "$REPO/shell/fish/prompt.fish"
  printf 'fish-env\n'    > "$REPO/shell/fish/env.fish"

  # Create minimal scripts
  printf '#!/bin/sh\necho ll\n'     > "$REPO/scripts/bin/ll"
  printf '#!/bin/sh\necho dus\n'    > "$REPO/scripts/bin/dus"
  printf '#!/bin/sh\necho dusf\n'   > "$REPO/scripts/bin/dusf"
  printf '#!/bin/sh\necho dusf.\n'  > "$REPO/scripts/bin/dusf."
  chmod +x "$REPO/scripts/bin/"*

  # Stubs (uname, curl, fish) via PATH override.
  # Default uname -> Darwin (override per-test when needed).
  cat > "$STUBBIN/uname" <<'EOF'
#!/bin/sh
if [ "$1" = "-s" ]; then
  echo "${STUB_UNAME_S:-Darwin}"
else
  echo "${STUB_UNAME_S:-Darwin}"
fi
EOF
  chmod +x "$STUBBIN/uname"

  # curl stub prints deterministic content to stdout based on URL
  cat > "$STUBBIN/curl" <<'EOF'
#!/bin/sh
# Minimal stub for: curl -fsSL URL
# Always writes content to stdout; ignores flags.
url=""
for arg in "$@"; do
  case "$arg" in
    http://*|https://*)
      url="$arg"
      ;;
  esac
done
if [ -z "$url" ]; then
  echo "curl-stub: missing url" >&2
  exit 2
fi
case "$url" in
  */shell/*)
    echo "REMOTE:$url"
    ;;
  */scripts/bin/*)
    echo "#!/bin/sh"
    echo "echo REMOTE:$url"
    ;;
  *)
    echo "REMOTE:$url"
    ;;
esac
exit 0
EOF
  chmod +x "$STUBBIN/curl"

  # fish stub so "command -v fish" succeeds when testing fish shell path.
  cat > "$STUBBIN/fish" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$STUBBIN/fish"

  export PATH="$STUBBIN:$PATH"

  # Cache original PATH for deterministic PATH isolation in specific tests.
  export ORIG_PATH="$PATH"

  # Provide a predictable HOME for non-dry-run user mode tests
  export HOME="$TEST_TMP/home"
  mkdir -p "$HOME"
}

teardown() {
  :
}

# --- Helpers ---

# Assert that a file contains a line exactly once
assert_file_contains_once() {
  local file="$1"
  local needle="$2"
  local count
  count="$(grep -F "$needle" "$file" 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$count" -ne 1 ]; then
    {
      echo "file '$file' should contain '$needle' exactly once, but found $count times"
      echo "file contents:"
      cat "$file"
    } | flunk
  fi
}

# Assert that a file does not contain a line
assert_file_not_contains() {
  local file="$1"
  local needle="$2"
  if grep -qF "$needle" "$file" 2>/dev/null; then
    {
      echo "file '$file' should not contain '$needle'"
      echo "file contents:"
      cat "$file"
    } | flunk
  fi
}

# Helper: Build a minimal PATH with required tools, but omitting fish.
make_min_path_without_fish() {
  local mp="$TEST_TMP/minpath_no_fish"
  rm -rf "$mp"
  mkdir -p "$mp"

  # Put our stubs first.
  ln -s "$STUBBIN/uname" "$mp/uname"
  ln -s "$STUBBIN/curl" "$mp/curl"

  # Link required basic tools from the system (do not include fish).
  for cmd in bash sh mkdir cp chmod touch grep dirname basename head printf cat wc tr; do
    if command -v "$cmd" >/dev/null 2>&1; then
      ln -s "$(command -v "$cmd")" "$mp/$cmd"
    fi
  done

  echo "$mp"
}

# --- Tests: CLI parsing / validation ---

@test "help: -h exits 0 and prints Usage" {
  run "$REPO/install.sh" -h
  assert_success
  assert_output --partial "Usage:"
}

@test "unknown option: exits 1 and prints Unknown option" {
  run "$REPO/install.sh" --nope
  assert_failure
  assert_output --partial "Unknown option:"
}

@test "--repo-root without arg: exits 1 with error" {
  run "$REPO/install.sh" --repo-root
  assert_failure
  assert_output --partial "Error: --repo-root requires a path argument"
}

@test "--bin-prefix without arg: exits 1 with error" {
  run "$REPO/install.sh" --bin-prefix
  assert_failure
  assert_output --partial "Error: --bin-prefix requires a path argument"
}

@test "conflicting flags: --settings-only and --scripts-only => error" {
  run "$REPO/install.sh" --settings-only --scripts-only
  assert_failure
  assert_output --partial "Error: --settings-only and --scripts-only cannot be used together"
}

@test "--repo-root with remote mode => error" {
  run "$REPO/install.sh" --repo-root "$REPO"
  assert_failure
  assert_output --partial "Error: --repo-root can only be used with --local"
}

# --- Tests: dry-run validation ---

@test "dry-run path must be absolute" {
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run=relative -y
  assert_failure
  assert_output --partial "Error: --dry-run path must be absolute"
}

@test "dry-run requires -y/--yes (fails before prompting) when missing -y" {
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX"
  assert_failure
  assert_output --partial "Dry-run mode requires -y/--yes"
}

# --- Tests: OS detection guard ---

@test "unsupported OS => die" {
  export STUB_UNAME_S="FreeBSD"
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_failure
  assert_output --partial "Unsupported OS:"
}

# --- Tests: shell detection guard ---

@test "unsupported shell => die" {
  export SHELL="/bin/tcsh"
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_failure
  assert_output --partial "Unsupported shell:"
}

@test "fish selected but fish binary missing => die" {
  export SHELL="/usr/bin/fish"

  # Build an isolated PATH that includes required tools but intentionally omits fish.
  local mp
  mp="$(make_min_path_without_fish)"

  run env PATH="$mp" "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_failure
  assert_output --partial "fish binary not found"
}

# --- Tests: local mode install (dry-run sandbox) ---

@test "dry-run local default: installs settings+scripts into sandbox with bash rc (.bash_profile)" {
  export SHELL="/bin/bash"
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_success

  # RC file
  [ -f "$SANDBOX/HOME/.bash_profile" ]

  # Settings files
  [ -f "$SANDBOX/HOME/.my-shell/bash/init.bash" ]
  [ -f "$SANDBOX/HOME/.my-shell/bash/aliases.bash" ]
  [ -f "$SANDBOX/HOME/.my-shell/bash/prompt.bash" ]
  [ -f "$SANDBOX/HOME/.my-shell/bash/env.bash" ]

  # Settings should not be executable
  [ ! -x "$SANDBOX/HOME/.my-shell/bash/init.bash" ]

  # Scripts default bin prefix (/usr/local/bin mapped into sandbox)
  [ -x "$SANDBOX/usr/local/bin/ll" ]
  [ -x "$SANDBOX/usr/local/bin/dus" ]
  [ -x "$SANDBOX/usr/local/bin/dusf" ]
  [ -x "$SANDBOX/usr/local/bin/dusf." ]

  # RC lines (sandbox paths are used in dry-run)
  assert_file_contains_once "$SANDBOX/HOME/.bash_profile" "source \"$SANDBOX/HOME/.my-shell/bash/init.bash\""
  assert_file_contains_once "$SANDBOX/HOME/.bash_profile" "export PATH=\"$SANDBOX/usr/local/bin:\$PATH\""
}

@test "dry-run local zsh: rc is .zshrc and source line points to zsh init" {
  export SHELL="/bin/zsh"
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_success

  [ -f "$SANDBOX/HOME/.zshrc" ]
  [ -f "$SANDBOX/HOME/.my-shell/zsh/init.zsh" ]
  assert_file_contains_once "$SANDBOX/HOME/.zshrc" "source \"$SANDBOX/HOME/.my-shell/zsh/init.zsh\""
  assert_file_contains_once "$SANDBOX/HOME/.zshrc" "export PATH=\"$SANDBOX/usr/local/bin:\$PATH\""
}

@test "dry-run local fish: rc is config.fish and PATH line uses fish syntax" {
  export SHELL="/usr/bin/fish"
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_success

  [ -f "$SANDBOX/HOME/.config/fish/config.fish" ]
  [ -f "$SANDBOX/HOME/.my-shell/fish/init.fish" ]
  assert_file_contains_once "$SANDBOX/HOME/.config/fish/config.fish" "source \"$SANDBOX/HOME/.my-shell/fish/init.fish\""
  assert_file_contains_once "$SANDBOX/HOME/.config/fish/config.fish" "set -gx PATH \"$SANDBOX/usr/local/bin\" \$PATH"
}

@test "dry-run local: --settings-only installs settings and does not install scripts nor PATH line" {
  export SHELL="/bin/zsh"
  run "$REPO/install.sh" --local --repo-root "$REPO" --settings-only --dry-run="$SANDBOX" -y
  assert_success

  [ -f "$SANDBOX/HOME/.zshrc" ]
  [ -f "$SANDBOX/HOME/.my-shell/zsh/init.zsh" ]
  [ ! -e "$SANDBOX/usr/local/bin/ll" ]

  # Source line exists, PATH line should not
  assert_file_contains_once "$SANDBOX/HOME/.zshrc" "source \"$SANDBOX/HOME/.my-shell/zsh/init.zsh\""
  assert_file_not_contains "$SANDBOX/HOME/.zshrc" "export PATH="
}

@test "dry-run local: --scripts-only installs scripts and PATH line but does not install shell settings files" {
  export SHELL="/bin/bash"
  run "$REPO/install.sh" --local --repo-root "$REPO" --scripts-only --dry-run="$SANDBOX" -y
  assert_success

  [ -f "$SANDBOX/HOME/.bash_profile" ]
  [ -x "$SANDBOX/usr/local/bin/ll" ]
  [ ! -e "$SANDBOX/HOME/.my-shell/bash/init.bash" ]

  # PATH line exists, source line should not
  assert_file_contains_once "$SANDBOX/HOME/.bash_profile" "export PATH=\"$SANDBOX/usr/local/bin:\$PATH\""
  assert_file_not_contains "$SANDBOX/HOME/.bash_profile" "source "
}

@test "dry-run local: idempotent append (running twice does not duplicate source/PATH lines)" {
  export SHELL="/bin/bash"

  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_success
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_success

  assert_file_contains_once "$SANDBOX/HOME/.bash_profile" "source \"$SANDBOX/HOME/.my-shell/bash/init.bash\""
  assert_file_contains_once "$SANDBOX/HOME/.bash_profile" "export PATH=\"$SANDBOX/usr/local/bin:\$PATH\""
}

@test "dry-run local: missing local source file => dies with Missing local source" {
  export SHELL="/bin/bash"
  rm -f "$REPO/shell/bash/prompt.bash"

  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_failure
  assert_output --partial "Missing local source:"
}

# --- Tests: BIN_PREFIX precedence and mapping ---

@test "dry-run: default BIN_PREFIX_REAL=/usr/local/bin maps to SANDBOX/usr/local/bin" {
  export SHELL="/bin/zsh"
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_success
  [ -x "$SANDBOX/usr/local/bin/ll" ]
}

@test "dry-run: --user => bin prefix maps to SANDBOX/HOME/.local/bin" {
  export SHELL="/bin/zsh"
  run "$REPO/install.sh" --local --repo-root "$REPO" --user --dry-run="$SANDBOX" -y
  assert_success

  [ -x "$SANDBOX/HOME/.local/bin/ll" ]
  assert_file_contains_once "$SANDBOX/HOME/.zshrc" "export PATH=\"$SANDBOX/HOME/.local/bin:\$PATH\""
}

@test "dry-run: MY_SHELL_BIN_PREFIX absolute overrides --user and maps to SANDBOX + abs" {
  export SHELL="/bin/bash"
  export MY_SHELL_BIN_PREFIX="/custom/bin"
  run "$REPO/install.sh" --local --repo-root "$REPO" --user --dry-run="$SANDBOX" -y
  assert_success

  [ -x "$SANDBOX/custom/bin/ll" ]
  assert_file_contains_once "$SANDBOX/HOME/.bash_profile" "export PATH=\"$SANDBOX/custom/bin:\$PATH\""
}

@test "dry-run: --bin-prefix overrides MY_SHELL_BIN_PREFIX and --user" {
  export SHELL="/bin/bash"
  export MY_SHELL_BIN_PREFIX="/custom/bin"
  run "$REPO/install.sh" --local --repo-root "$REPO" --user --bin-prefix /override/bin --dry-run="$SANDBOX" -y
  assert_success

  [ -x "$SANDBOX/override/bin/ll" ]
  [ ! -e "$SANDBOX/custom/bin/ll" ]
  assert_file_contains_once "$SANDBOX/HOME/.bash_profile" "export PATH=\"$SANDBOX/override/bin:\$PATH\""
}

@test "dry-run: MY_SHELL_BIN_PREFIX under real HOME maps to EFFECTIVE_HOME path" {
  export SHELL="/bin/zsh"

  # Use a distinct real HOME for mapping test
  export HOME="$TEST_TMP/realhome1"
  mkdir -p "$HOME"
  export MY_SHELL_BIN_PREFIX="$HOME/alt/bin"

  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y
  assert_success

  # Mapped to SANDBOX/HOME + suffix
  [ -x "$SANDBOX/HOME/alt/bin/ll" ]
  assert_file_contains_once "$SANDBOX/HOME/.zshrc" "export PATH=\"$SANDBOX/HOME/alt/bin:\$PATH\""
}

# --- Tests: overwrite behavior ---

@test "dry-run: existing destination + -y overwrites silently (no prompt)" {
  export SHELL="/bin/bash"
  mkdir -p "$SANDBOX/usr/local/bin"
  printf 'OLD\n' > "$SANDBOX/usr/local/bin/ll"

  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y --scripts-only
  assert_success

  # Should be overwritten by repo script content
  run sh -c "cat \"$SANDBOX/usr/local/bin/ll\" | head -n 1"
  assert_success
  assert_output "#!/bin/sh"
}

@test "non-dry-run: overwrite prompt declines => aborts" {
  export SHELL="/bin/zsh"
  export HOME="$TEST_TMP/home2"
  mkdir -p "$HOME"
  local bin="$HOME/.local/bin"
  mkdir -p "$bin"
  printf 'OLD\n' > "$bin/ll"

  # Run without -y so prompt is active; feed "n"
  run bash -c "printf 'n\n' | \"$REPO/install.sh\" --local --repo-root \"$REPO\" --user --scripts-only"
  assert_failure
  assert_output --partial "Aborted by user."
}

@test "non-dry-run: overwrite prompt accepts => overwrites" {
  export SHELL="/bin/zsh"
  export HOME="$TEST_TMP/home3"
  mkdir -p "$HOME"
  local bin="$HOME/.local/bin"
  mkdir -p "$bin"
  printf 'OLD\n' > "$bin/ll"

  run bash -c "printf 'y\n' | \"$REPO/install.sh\" --local --repo-root \"$REPO\" --user --scripts-only"
  assert_success
  run sh -c "cat \"$bin/ll\" | head -n 2"
  assert_success
  assert_output --partial "#!/bin/sh"
}

# --- Tests: remote mode via curl stub (no network) ---

@test "dry-run remote: installs using curl stub content (bash)" {
  export SHELL="/bin/bash"
  run "$REPO/install.sh" --dry-run="$SANDBOX" -y
  assert_success

  [ -f "$SANDBOX/HOME/.my-shell/bash/init.bash" ]
  # The remote settings file should contain "REMOTE:" prefix from curl stub
  run sh -c "head -n 1 \"$SANDBOX/HOME/.my-shell/bash/init.bash\""
  assert_success
  assert_output --regexp "^REMOTE:"

  # Remote scripts should be executable and contain REMOTE url
  [ -x "$SANDBOX/usr/local/bin/ll" ]
  run sh -c "\"$SANDBOX/usr/local/bin/ll\""
  assert_success
  assert_output --regexp "^REMOTE:"
}

@test "dry-run remote: MY_SHELL_REMOTE_BASE is used in URL composition" {
  export SHELL="/bin/zsh"
  export MY_SHELL_REMOTE_BASE="https://example.invalid/base"
  run "$REPO/install.sh" --dry-run="$SANDBOX" -y
  assert_success

  run sh -c "head -n 1 \"$SANDBOX/HOME/.my-shell/zsh/init.zsh\""
  assert_success
  assert_output --regexp "^REMOTE:https://example.invalid/base/"
}

# --- Tests: permission errors (sandbox) ---

@test "dry-run: bin prefix not writable => dies with guidance (non-/usr/local/bin case)" {
  export SHELL="/bin/bash"

  # Force bin prefix to a sandbox path and then make it non-writable
  mkdir -p "$SANDBOX/locked/bin"
  chmod 0555 "$SANDBOX/locked/bin"

  run "$REPO/install.sh" --local --repo-root "$REPO" --bin-prefix /locked/bin --dry-run="$SANDBOX" -y --scripts-only
  assert_failure
  assert_output --partial "Cannot write to"
}

@test "dry-run: /usr/local/bin not writable message mentions sudo or --user/--bin-prefix" {
  export SHELL="/bin/bash"

  mkdir -p "$SANDBOX/usr/local/bin"
  chmod 0555 "$SANDBOX/usr/local/bin"

  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y --scripts-only
  assert_failure
  assert_output --partial "Please run with sudo"
  assert_output --partial "--user"
  assert_output --partial "--bin-prefix"
}

# --- Tests: local repo-root auto-detection ---

@test "local mode without --repo-root uses install.sh directory as repo root" {
  export SHELL="/bin/zsh"
  # Invoke fixture repo install.sh with --local but without repo-root
  run "$REPO/install.sh" --local --dry-run="$SANDBOX" -y
  assert_success

  [ -f "$SANDBOX/HOME/.my-shell/zsh/init.zsh" ]
  [ -x "$SANDBOX/usr/local/bin/ll" ]
}

# --- Tests: scripts list completeness ---

@test "installs all expected scripts (ll dus dusf dusf.)" {
  export SHELL="/bin/bash"
  run "$REPO/install.sh" --local --repo-root "$REPO" --dry-run="$SANDBOX" -y --scripts-only
  assert_success

  [ -e "$SANDBOX/usr/local/bin/ll" ]
  [ -e "$SANDBOX/usr/local/bin/dus" ]
  [ -e "$SANDBOX/usr/local/bin/dusf" ]
  [ -e "$SANDBOX/usr/local/bin/dusf." ]
}