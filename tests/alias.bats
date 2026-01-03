#!/usr/bin/env bats
# Test suite for alias.sh

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup: Source the alias file before each test
setup() {
  # Get the directory where this test file is located
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
  
  # Source alias.sh
  source "$PROJECT_ROOT/alias.sh"
}

@test "alias.sh can be sourced without errors" {
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

@test "cd_aliases function creates navigation aliases" {
  # cd_aliases is called and unset in alias.sh, so we check for the aliases it creates
  # Check if cdh alias is created
  run alias cdh
  assert_success
  
  # Check if .1 alias is created
  run alias .1
  assert_success
  
  # Check if .. alias is created
  run alias ..
  assert_success
}

@test "ls_aliases function creates listing aliases" {
  # ls_aliases is called and unset in alias.sh, so we check for the aliases it creates
  # Check if ls alias is created
  run alias ls
  assert_success
  
  # Check if la alias is created
  run alias la
  assert_success
  
  # Check if ll alias is created (if available)
  if hash ll 2>/dev/null || type ll >/dev/null 2>&1; then
    run alias ll
    assert_success
  fi
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

@test "print_files function is defined" {
  run type print_files
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "print_files"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "hs function is defined" {
  run type hs
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "hs"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "get_distro function is defined" {
  run type get_distro
  assert_success
  # Check for function definition (works in both English and Turkish)
  assert_output --partial "get_distro"
  assert_output --partial "function" || assert_output --partial "işlev"
}

@test "clear alias is defined" {
  run alias c
  assert_success
}

@test "rm! alias is defined" {
  run alias 'rm!'
  assert_success
}

@test "fhere alias is defined" {
  run alias fhere
  assert_success
}

@test "h alias is defined (history)" {
  run alias h
  assert_success
}

@test "hg alias is defined (history grep)" {
  run alias hg
  assert_success
}

@test "j alias is defined (jobs)" {
  run alias j
  assert_success
}

@test "path alias is defined" {
  run alias path
  assert_success
}

@test "now alias is defined" {
  run alias now
  assert_success
}

@test "nowtime alias is defined" {
  run alias nowtime
  assert_success
}

@test "nowdate alias is defined" {
  run alias nowdate
  assert_success
}

@test "du alias is defined" {
  run alias du
  assert_success
}

@test "myip alias is defined" {
  run alias myip
  assert_success
}

@test "ports alias is defined" {
  run alias ports
  assert_success
}

@test "mcd function creates directory" {
  TEST_DIR=$(mktemp -d)
  TEST_SUBDIR="$TEST_DIR/test_subdir"
  
  # mcd is run in a subshell, so we can't check PWD change
  # But we can check if directory is created
  run bash -c "source '$PROJECT_ROOT/alias.sh' && mcd '$TEST_SUBDIR' && [ -d '$TEST_SUBDIR' ]"
  assert_success
  
  # Verify directory was created
  [ -d "$TEST_SUBDIR" ]
  
  # Cleanup
  rm -rf "$TEST_DIR"
}


