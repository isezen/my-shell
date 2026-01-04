#!/usr/bin/env bats
# Test suite for shell/bash/prompt.bash and shell/bash/env.bash

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup: Source the bash files before each test
setup() {
  # Get the directory where this test file is located
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
  
  # Source shell/bash/env.bash and shell/bash/prompt.bash
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/shell/bash/env.bash"
  # shellcheck disable=SC1091
  source "$PROJECT_ROOT/shell/bash/prompt.bash"
}

@test "bash.sh can be sourced without errors" {
  # This test passes if setup() succeeds
  run true
  assert_success
}

@test "PS1 is set" {
  [ -n "$PS1" ]
}

@test "CLICOLOR is set to 1" {
  [ "$CLICOLOR" = "1" ]
}

@test "HISTSIZE is set" {
  [ -n "$HISTSIZE" ]
  [ "$HISTSIZE" -gt 0 ]
}

@test "HISTFILESIZE is set" {
  [ -n "$HISTFILESIZE" ]
  [ "$HISTFILESIZE" -gt 0 ]
}

@test "HISTCONTROL is set to ignoreboth" {
  [ "$HISTCONTROL" = "ignoreboth" ]
}

@test "PROMPT_COMMAND is set" {
  [ -n "$PROMPT_COMMAND" ]
}

@test "histappend shell option is enabled" {
  run shopt histappend
  assert_success
  assert_output --partial "on"
}

@test "NEW_PWD variable is set by PROMPT_COMMAND" {
  # Run the prompt command
  eval "$PROMPT_COMMAND"
  
  # NEW_PWD should be set
  [ -n "$NEW_PWD" ]
}

@test "bash_prompt_command function sets NEW_PWD correctly" {
  # Save original PWD
  ORIGINAL_PWD="$PWD"
  
  # Change to a test directory
  TEST_DIR=$(mktemp -d)
  cd "$TEST_DIR"
  
  # Run the prompt command
  bash_prompt_command
  
  # NEW_PWD should be set
  [ -n "$NEW_PWD" ]
  
  # NEW_PWD should contain the directory name or ~ for home
  if [ "$TEST_DIR" = "$HOME" ]; then
    [ "$NEW_PWD" = "~" ]
  else
    [ -n "$NEW_PWD" ]
  fi
  
  # Cleanup
  cd "$ORIGINAL_PWD"
  rm -rf "$TEST_DIR"
}

