#!/usr/bin/env bats
# Test suite for shell/bash/aliases.bash

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup: Source the alias file before each test
setup() {
  # Get the directory where this test file is located
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
  
  # Source shell/bash/aliases.bash
  source "$PROJECT_ROOT/shell/bash/aliases.bash"
}

@test "shell/bash/aliases.bash can be sourced without errors" {
  # This test passes if setup() succeeds
  run true
  assert_success
}

@test "mem function is defined" {
  run type mem
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "mem"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "cdh function is defined" {
  run type cdh
  assert_success
  assert_output --partial "cdh"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "navigation functions are defined" {
  # Check if .1 function is created
  run type .1
  assert_success
  
  # Check if .. function is created
  run type ..
  assert_success
}

@test "ls function is defined" {
  run type ls
  assert_success
  assert_output --partial "ls"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "la function is defined" {
  run type la
  assert_success
  assert_output --partial "la"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "ll function is defined" {
  run type ll
  assert_success
  assert_output --partial "ll"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "mcd function is defined" {
  run type mcd
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "mcd"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "FindFiles function is defined" {
  run type FindFiles
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "FindFiles"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "dushf function is defined" {
  run type dushf
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "dushf"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "dufiles function is defined" {
  run type dufiles
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "dufiles"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "dusd function is defined" {
  run type dusd
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "dusd"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "hs function is defined" {
  run type hs
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "hs"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "c function is defined (clear)" {
  run type c
  assert_success
  assert_output --partial "c"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "rm! function is defined" {
  run type 'rm!'
  assert_success
  assert_output --partial "rm!"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "fhere function is defined" {
  run type fhere
  assert_success
  assert_output --partial "fhere"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "h function is defined (history)" {
  run type h
  assert_success
  assert_output --partial "h"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "hg function is defined (history grep)" {
  # hg is only defined if grep is available
  if command -v grep >/dev/null 2>&1; then
    run type hg
    assert_success
    assert_output --partial "hg"
    assert_output --partial "function" || assert_output --partial "işlev"
  else
    skip "grep not available"
  fi
}

@test "j function is defined (jobs)" {
  run type j
  assert_success
  assert_output --partial "j"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "showpath function is defined" {
  run type showpath
  assert_success
  assert_output --partial "showpath"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "now function is defined" {
  run type now
  assert_success
  assert_output --partial "now"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "nowtime function is defined" {
  run type nowtime
  assert_success
  assert_output --partial "nowtime"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "nowdate function is defined" {
  run type nowdate
  assert_success
  assert_output --partial "nowdate"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "du function is defined (if available)" {
  # du is conditionally defined based on system
  if type du >/dev/null 2>&1; then
    run type du
    assert_success
    assert_output --partial "du"
    assert_output --partial "function" || assert_output --partial "işlev"
  else
    skip "du function not available on this system"
  fi
}

@test "myip function is defined (if available)" {
  # myip is conditionally defined based on curl/wget/fetch availability
  if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || command -v fetch >/dev/null 2>&1; then
    run type myip
    assert_success
    assert_output --partial "myip"
    assert_output --partial "function" || assert_output --partial "işlev"
  else
    skip "myip function not available (requires curl, wget, or fetch)"
  fi
}

@test "ports function is defined (if available)" {
  # ports is conditionally defined based on system and available tools
  if type ports >/dev/null 2>&1; then
    run type ports
    assert_success
    assert_output --partial "ports"
    assert_output --partial "function" || assert_output --partial "işlev"
  else
    skip "ports function not available on this system"
  fi
}

@test "mcd function creates directory" {
  TEST_DIR=$(mktemp -d)
  TEST_SUBDIR="$TEST_DIR/test_subdir"
  
  # mcd is run in a subshell, so we can't check PWD change
  # But we can check if directory is created
  run bash -c "source '$PROJECT_ROOT/shell/bash/aliases.bash' && mcd '$TEST_SUBDIR' && [ -d '$TEST_SUBDIR' ]"
  assert_success
  
  # Verify directory was created
  [ -d "$TEST_SUBDIR" ]
  
  # Cleanup
  rm -rf "$TEST_DIR"
}


