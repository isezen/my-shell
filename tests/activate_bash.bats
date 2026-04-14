#!/usr/bin/env bats
# tests/activate_bash.bats
#
# Lock the contract of `env/activate.bash` (source mode only). Each test
# runs a fresh `bash --noprofile --norc` subshell so the BATS process and
# the user's interactive bash environment are not polluted, and so the
# user's ~/.bashrc cannot interfere with the assertions.
#
# Out of scope:
#   * `./env/activate` spawn mode (requires an interactive terminal)
#   * Interactive PS1 rendering (cosmetic, terminal-only)
#   * MY_SHELL_TMPDIR cleanup beyond unset (depends on caller-provided dir)

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  ACTIVATE="${PROJECT_ROOT}/env/activate.bash"
  export PROJECT_ROOT ACTIVATE
  : "${ACTIVATE:?}"
  [ -r "$ACTIVATE" ] || skip "env/activate.bash not readable"
}

# Helper: run a one-shot bash with activate sourced and execute $1 inside.
# Exported so `run _in_activated_bash ...` can find it inside bats's
# subshell. `set -u` is enabled deliberately: activate.bash's defensive-
# coding contract (use `${VAR:-}` defaults for every potentially-unset
# MY_SHELL_* / PS1 reference) is locked in by this flag. If a future
# edit reintroduces a bare `"$VAR"` on an unset variable, every test in
# this file fails with `unbound variable` — which is the regression
# signal we want.
_in_activated_bash() {
  local body="$1"
  bash --noprofile --norc -c "
    set -u
    PROJECT_ROOT='${PROJECT_ROOT}'
    ACTIVATE='${ACTIVATE}'
    # Capture the original PATH so the test body can compare against it.
    ORIGINAL_PATH=\"\$PATH\"
    source \"\$ACTIVATE\" >/dev/null
    ${body}
  "
}
export -f _in_activated_bash

@test "activate.bash: source sets MY_SHELL_ACTIVATED=1" {
  run _in_activated_bash 'echo "MY_SHELL_ACTIVATED=$MY_SHELL_ACTIVATED"'
  assert_success
  assert_output --partial "MY_SHELL_ACTIVATED=1"
}

@test "activate.bash: source sets MY_SHELL_ROOT to the repo root" {
  run _in_activated_bash 'echo "ROOT=$MY_SHELL_ROOT"'
  assert_success
  assert_output --partial "ROOT=${PROJECT_ROOT}"
}

@test "activate.bash: source saves MY_SHELL_OLD_PATH equal to pre-source PATH" {
  run _in_activated_bash '
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

@test "activate.bash: source prepends scripts/bin and scripts/dev to PATH" {
  run _in_activated_bash 'echo "PATH=$PATH"'
  assert_success
  assert_output --regexp "PATH=${PROJECT_ROOT}/scripts/bin:${PROJECT_ROOT}/scripts/dev:"
}

@test "activate.bash: deactivate function is defined after source" {
  run _in_activated_bash 'declare -F deactivate'
  assert_success
  assert_output --partial "deactivate"
}

@test "activate.bash: reactivate function is defined after source" {
  run _in_activated_bash 'declare -F reactivate'
  assert_success
  assert_output --partial "reactivate"
}

@test "activate.bash: deactivate restores PATH to MY_SHELL_OLD_PATH" {
  run _in_activated_bash '
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

@test "activate.bash: deactivate unsets MY_SHELL_* env vars" {
  run _in_activated_bash '
    deactivate >/dev/null
    leaked=""
    for v in MY_SHELL_ACTIVATED MY_SHELL_ROOT MY_SHELL_OLD_PATH MY_SHELL_OLD_PS1 MY_SHELL_ACTIVATION_MODE; do
      if [ -n "${!v:-}" ]; then leaked="$leaked $v"; fi
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

@test "activate.bash: deactivate unsets deactivate and reactivate functions" {
  run _in_activated_bash '
    deactivate >/dev/null
    if declare -F deactivate >/dev/null 2>&1; then
      echo "deactivate STILL DEFINED"
    elif declare -F reactivate >/dev/null 2>&1; then
      echo "reactivate STILL DEFINED"
    else
      echo FUNCTIONS_REMOVED
    fi
  '
  assert_success
  assert_output --partial "FUNCTIONS_REMOVED"
}

@test "activate.bash: re-sourcing while activated prints already-activated message" {
  run _in_activated_bash '
    source "$ACTIVATE"
  '
  assert_success
  assert_output --partial "already activated"
}

@test "activate.bash: reactivate fails after deactivate (no longer defined)" {
  run _in_activated_bash '
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
