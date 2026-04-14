#!/usr/bin/env bats
# tests/activate_fish.bats
#
# Mirror of activate_bash.bats / activate_zsh.bats but invokes
# `fish -c 'source ...'`. Fish's syntax differs from bash/zsh (set vs
# export, set -q for defined-check, functions -q for function-check,
# if ... ; end blocks, no bash parameter expansion), so test bodies are
# rewritten in fish.
#
# Soft-skipped if `fish` binary is not installed.

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  ACTIVATE="${PROJECT_ROOT}/env/activate.fish"
  export PROJECT_ROOT ACTIVATE
  if ! command -v fish >/dev/null 2>&1; then
    skip "fish binary not installed"
  fi
  [ -r "$ACTIVATE" ] || skip "env/activate.fish not readable"
}

# Helper: fish -c with activate sourced. fish --no-config skips
# config.fish so the user's interactive setup doesn't pollute the test.
_in_activated_fish() {
  local body="$1"
  fish --no-config -c "
    set -gx PROJECT_ROOT '${PROJECT_ROOT}'
    set -gx ACTIVATE '${ACTIVATE}'
    set -gx ORIGINAL_PATH \$PATH
    source \"\$ACTIVATE\" >/dev/null
    ${body}
  "
}
export -f _in_activated_fish

@test "activate.fish: source sets MY_SHELL_ACTIVATED=1" {
  run _in_activated_fish 'echo "MY_SHELL_ACTIVATED=$MY_SHELL_ACTIVATED"'
  assert_success
  assert_output --partial "MY_SHELL_ACTIVATED=1"
}

@test "activate.fish: source sets MY_SHELL_ROOT to the repo root" {
  run _in_activated_fish 'echo "ROOT=$MY_SHELL_ROOT"'
  assert_success
  assert_output --partial "ROOT=${PROJECT_ROOT}"
}

@test "activate.fish: source saves MY_SHELL_OLD_PATH equal to pre-source PATH" {
  # In fish, PATH is a list; compare element-by-element via joined string.
  run _in_activated_fish '
    set old_joined (string join : $MY_SHELL_OLD_PATH)
    set orig_joined (string join : $ORIGINAL_PATH)
    if test "$old_joined" = "$orig_joined"
      echo MATCH
    else
      echo "OLD=$old_joined"
      echo "ORIG=$orig_joined"
    end
  '
  assert_success
  assert_output --partial "MATCH"
}

@test "activate.fish: source prepends scripts/bin and scripts/dev to PATH" {
  # Fish stores PATH as a list. Quoted "$PATH" coalesces it with colons
  # (POSIX-compat); unquoted $PATH expands element-per-token. We use the
  # joined-with-colon form to keep the assertion deterministic regardless
  # of how many other path entries are inherited from the parent env.
  run _in_activated_fish 'echo "PATH=$PATH"'
  assert_success
  assert_output --regexp "PATH=${PROJECT_ROOT}/scripts/bin:${PROJECT_ROOT}/scripts/dev:"
}

@test "activate.fish: deactivate function is defined after source" {
  run _in_activated_fish '
    if functions -q deactivate
      echo DEFINED
    else
      echo MISSING
    end
  '
  assert_success
  assert_output --partial "DEFINED"
}

@test "activate.fish: reactivate function is defined after source" {
  run _in_activated_fish '
    if functions -q reactivate
      echo DEFINED
    else
      echo MISSING
    end
  '
  assert_success
  assert_output --partial "DEFINED"
}

@test "activate.fish: deactivate restores PATH to MY_SHELL_OLD_PATH" {
  run _in_activated_fish '
    set saved $MY_SHELL_OLD_PATH
    deactivate >/dev/null
    set saved_joined (string join : $saved)
    set now_joined (string join : $PATH)
    if test "$saved_joined" = "$now_joined"
      echo PATH_RESTORED
    else
      echo "POST=$now_joined"
      echo "EXPECTED=$saved_joined"
    end
  '
  assert_success
  assert_output --partial "PATH_RESTORED"
}

@test "activate.fish: deactivate unsets MY_SHELL_* env vars" {
  run _in_activated_fish '
    deactivate >/dev/null
    set -l leaked
    for v in MY_SHELL_ACTIVATED MY_SHELL_ROOT MY_SHELL_OLD_PATH MY_SHELL_ACTIVATION_MODE
      if set -q $v
        set -a leaked $v
      end
    end
    if test (count $leaked) -eq 0
      echo CLEAN
    else
      echo "LEAKED:$leaked"
    end
  '
  assert_success
  assert_output --partial "CLEAN"
}

@test "activate.fish: deactivate removes deactivate and reactivate functions" {
  run _in_activated_fish '
    deactivate >/dev/null
    if functions -q deactivate
      echo "deactivate STILL DEFINED"
    else if functions -q reactivate
      echo "reactivate STILL DEFINED"
    else
      echo FUNCTIONS_REMOVED
    end
  '
  assert_success
  assert_output --partial "FUNCTIONS_REMOVED"
}

@test "activate.fish: re-sourcing while activated prints already-activated message" {
  run _in_activated_fish 'source "$ACTIVATE"'
  assert_success
  assert_output --partial "already activated"
}

@test "activate.fish: reactivate fails after deactivate (no longer defined)" {
  run _in_activated_fish '
    deactivate >/dev/null
    if reactivate 2>/dev/null
      echo UNEXPECTED_SUCCESS
    else
      echo EXPECTED_FAILURE
    end
  '
  assert_success
  assert_output --partial "EXPECTED_FAILURE"
}
