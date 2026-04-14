#!/usr/bin/env bats
# tests/activate_zsh.bats
#
# Mirror of activate_bash.bats but invokes `zsh -c 'source ...'` so the
# zsh-specific activation script is exercised. Same scope rules: source
# mode only, no interactive PS1/PROMPT, no spawn flag.
#
# Soft-skipped if `zsh` binary is not installed (Ubuntu CI does not
# include zsh by default; macOS CI does).

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  ACTIVATE="${PROJECT_ROOT}/env/activate.zsh"
  export PROJECT_ROOT ACTIVATE
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh binary not installed"
  fi
  [ -r "$ACTIVATE" ] || skip "env/activate.zsh not readable"
}

# Helper: zsh -c with activate sourced. zsh's --no-rcs --no-globalrcs
# suppress the user's zshrc / zshenv so the test environment is clean.
_in_activated_zsh() {
  local body="$1"
  zsh --no-rcs --no-globalrcs -c "
    PROJECT_ROOT='${PROJECT_ROOT}'
    ACTIVATE='${ACTIVATE}'
    ORIGINAL_PATH=\"\$PATH\"
    source \"\$ACTIVATE\" >/dev/null
    ${body}
  "
}
export -f _in_activated_zsh

@test "activate.zsh: source sets MY_SHELL_ACTIVATED=1" {
  run _in_activated_zsh 'echo "MY_SHELL_ACTIVATED=$MY_SHELL_ACTIVATED"'
  assert_success
  assert_output --partial "MY_SHELL_ACTIVATED=1"
}

@test "activate.zsh: source sets MY_SHELL_ROOT to the repo root" {
  run _in_activated_zsh 'echo "ROOT=$MY_SHELL_ROOT"'
  assert_success
  assert_output --partial "ROOT=${PROJECT_ROOT}"
}

@test "activate.zsh: source saves MY_SHELL_OLD_PATH equal to pre-source PATH" {
  run _in_activated_zsh '
    if [ "$MY_SHELL_OLD_PATH" = "$ORIGINAL_PATH" ]; then
      echo MATCH
    else
      echo "OLD=$MY_SHELL_OLD_PATH"
      echo "ORIG=$ORIGINAL_PATH"
    fi
  '
  assert_success
  assert_output --partial "MATCH"
}

@test "activate.zsh: source prepends scripts/bin and scripts/dev to PATH" {
  run _in_activated_zsh 'echo "PATH=$PATH"'
  assert_success
  assert_output --regexp "PATH=${PROJECT_ROOT}/scripts/bin:${PROJECT_ROOT}/scripts/dev:"
}

@test "activate.zsh: deactivate function is defined after source" {
  run _in_activated_zsh 'whence -w deactivate'
  assert_success
  assert_output --partial "deactivate: function"
}

@test "activate.zsh: reactivate function is defined after source" {
  run _in_activated_zsh 'whence -w reactivate'
  assert_success
  assert_output --partial "reactivate: function"
}

@test "activate.zsh: deactivate restores PATH to MY_SHELL_OLD_PATH" {
  run _in_activated_zsh '
    SAVED="$MY_SHELL_OLD_PATH"
    deactivate >/dev/null
    if [ "$PATH" = "$SAVED" ]; then
      echo PATH_RESTORED
    else
      echo "POST_PATH=$PATH"
      echo "EXPECTED=$SAVED"
    fi
  '
  assert_success
  assert_output --partial "PATH_RESTORED"
}

@test "activate.zsh: deactivate unsets MY_SHELL_* env vars" {
  run _in_activated_zsh '
    deactivate >/dev/null
    leaked=""
    for v in MY_SHELL_ACTIVATED MY_SHELL_ROOT MY_SHELL_OLD_PATH MY_SHELL_OLD_PS1 MY_SHELL_ACTIVATION_MODE; do
      eval "val=\${$v:-}"
      if [ -n "$val" ]; then leaked="$leaked $v"; fi
    done
    if [ -z "$leaked" ]; then
      echo CLEAN
    else
      echo "LEAKED:$leaked"
    fi
  '
  assert_success
  assert_output --partial "CLEAN"
}

@test "activate.zsh: deactivate unsets deactivate and reactivate functions" {
  run _in_activated_zsh '
    deactivate >/dev/null
    if whence -w deactivate 2>/dev/null | grep -q function; then
      echo "deactivate STILL DEFINED"
    elif whence -w reactivate 2>/dev/null | grep -q function; then
      echo "reactivate STILL DEFINED"
    else
      echo FUNCTIONS_REMOVED
    fi
  '
  assert_success
  assert_output --partial "FUNCTIONS_REMOVED"
}

@test "activate.zsh: re-sourcing while activated prints already-activated message" {
  run _in_activated_zsh '
    source "$ACTIVATE"
  '
  assert_success
  assert_output --partial "already activated"
}

@test "activate.zsh: reactivate fails after deactivate (no longer defined)" {
  run _in_activated_zsh '
    deactivate >/dev/null
    if reactivate 2>/dev/null; then
      echo UNEXPECTED_SUCCESS
    else
      echo EXPECTED_FAILURE
    fi
  '
  assert_success
  assert_output --partial "EXPECTED_FAILURE"
}
