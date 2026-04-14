#!/usr/bin/env bats
# tests/scripts_dus.bats
# Test suite for scripts/bin/{dus,dusf,dusf.}
#
# These legacy utilities require GNU coreutils (ls/du/head/sed -r).
# This suite exercises three regimes:
#   1. GNU available  — run the scripts end-to-end and assert real output
#   2. GNU missing    — assert the preflight error + exit 2
# The hostile-assert pattern ("[ $status -ge 0 ] && [ $status -le 2 ]")
# from the previous revision was replaced because it passed regardless
# of actual behavior — any of the three scripts could have been silently
# broken and the tests would still succeed.

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
  DUS_SCRIPT="$PROJECT_ROOT/scripts/bin/dus"
  DUSF_SCRIPT="$PROJECT_ROOT/scripts/bin/dusf"
  DUSFD_SCRIPT="$PROJECT_ROOT/scripts/bin/dusf."

  # Working directory with a predictable set of files.
  TEST_DIR_TMP=$(mktemp -d)
  cd "$TEST_DIR_TMP"
  echo "test content 1" > test_file1.txt
  echo "test content 2" > test_file2.txt
  mkdir test_dir1
  echo "test content 3" > test_dir1/file_in_dir.txt
  echo "hidden content" > .hidden1
}

teardown() {
  if [ -n "$TEST_DIR_TMP" ] && [ -d "$TEST_DIR_TMP" ]; then
    cd /tmp
    rm -rf "$TEST_DIR_TMP"
  fi
}

# Detect a GNU-coreutils-capable environment for the scripts under test.
# Returns 0 if GNU ls is reachable on PATH, 1 otherwise. Adjusts PATH in
# place to prepend the MacPorts / Homebrew gnubin directories when they
# exist, mirroring what tests/ll/20_baseline_snapshot.bats does for the
# `ll_linux` path.
_gnu_coreutils_available() {
  if ls --version >/dev/null 2>&1; then
    return 0
  fi
  local p
  for p in /opt/local/libexec/gnubin /opt/homebrew/opt/coreutils/libexec/gnubin /usr/local/opt/coreutils/libexec/gnubin; do
    if [ -x "$p/ls" ] && "$p/ls" --version >/dev/null 2>&1; then
      export PATH="$p:$PATH"
      return 0
    fi
  done
  return 1
}

# --- Existence & executability ----------------------------------------

@test "dus script exists and is executable" {
  [ -f "$DUS_SCRIPT" ]
  [ -x "$DUS_SCRIPT" ]
}

@test "dusf script exists and is executable" {
  [ -f "$DUSF_SCRIPT" ]
  [ -x "$DUSF_SCRIPT" ]
}

@test "dusf. script exists and is executable" {
  [ -f "$DUSFD_SCRIPT" ]
  [ -x "$DUSFD_SCRIPT" ]
}

# --- GNU available: real execution -------------------------------------

@test "dus: runs, exits 0, prints header and total on a GNU-coreutils host" {
  _gnu_coreutils_available || skip "GNU coreutils not available"

  run "$DUS_SCRIPT"
  assert_success
  [ -n "$output" ]
  # Horizontal rule that separates rows from the total line.
  assert_output --partial "------------"
  # The fixture has files the script should list by name.
  assert_output --partial "test_file1.txt"
  assert_output --partial "test_dir1"
}

@test "dusf: runs, exits 0, lists only regular non-hidden files" {
  _gnu_coreutils_available || skip "GNU coreutils not available"

  run "$DUSF_SCRIPT"
  assert_success
  assert_output --partial "test_file1.txt"
  assert_output --partial "test_file2.txt"
  # Directories and hidden files are excluded by design. The in-tree
  # bats-assert shim does not provide refute_output, so use bash
  # parameter expansion for the negative assertions.
  [[ "$output" != *"test_dir1"* ]] || {
    echo "unexpected: 'test_dir1' appeared in dusf output" >&2
    echo "output: $output" >&2
    return 1
  }
  [[ "$output" != *".hidden1"* ]] || {
    echo "unexpected: '.hidden1' appeared in dusf output" >&2
    echo "output: $output" >&2
    return 1
  }
}

@test "dusf.: runs, exits 0, lists only hidden files" {
  _gnu_coreutils_available || skip "GNU coreutils not available"

  run "$DUSFD_SCRIPT"
  assert_success
  assert_output --partial ".hidden1"
  # Non-hidden regular files are excluded by design.
  [[ "$output" != *"test_file1.txt"* ]] || {
    echo "unexpected: 'test_file1.txt' appeared in dusf. output" >&2
    echo "output: $output" >&2
    return 1
  }
}

# --- GNU missing: preflight guard --------------------------------------

@test "dus: exits 2 with 'GNU coreutils required' when GNU ls is missing" {
  # Force a BSD-only PATH so ls --version fails. On pure Linux this
  # makes `ls` unresolvable; the preflight uses `command ls` so it
  # still triggers (`command` returns non-zero on missing command,
  # which the `! ...` wrapper treats as the missing-GNU case).
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "BSD-userland probe only meaningful on Darwin"
  fi

  run env PATH="/usr/bin:/bin" "$DUS_SCRIPT"
  [ "$status" -eq 2 ]
  assert_output --partial "dus: GNU coreutils required."
  assert_output --partial "MacPorts: sudo port install coreutils"
  assert_output --partial "Homebrew: brew install coreutils"
}

@test "dusf: exits 2 with 'GNU coreutils required' when GNU ls is missing" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "BSD-userland probe only meaningful on Darwin"
  fi

  run env PATH="/usr/bin:/bin" "$DUSF_SCRIPT"
  [ "$status" -eq 2 ]
  assert_output --partial "dusf: GNU coreutils required."
}

@test "dusf.: exits 2 with 'GNU coreutils required' when GNU ls is missing" {
  if [ "$(uname -s)" != "Darwin" ]; then
    skip "BSD-userland probe only meaningful on Darwin"
  fi

  run env PATH="/usr/bin:/bin" "$DUSFD_SCRIPT"
  [ "$status" -eq 2 ]
  assert_output --partial "dusf.: GNU coreutils required."
}
