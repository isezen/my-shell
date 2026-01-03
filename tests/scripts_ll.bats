#!/usr/bin/env bats
# Test suite for scripts/ll

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup: Get script path
setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
  LL_SCRIPT="$PROJECT_ROOT/scripts/ll"
  
  # Create a test directory with some files
  TEST_DIR_TMP=$(mktemp -d)
  cd "$TEST_DIR_TMP"
  
  # Create test files
  touch test_file1.txt test_file2.txt
  mkdir test_dir1
  touch test_dir1/file_in_dir.txt
}

teardown() {
  # Cleanup test directory
  if [ -n "$TEST_DIR_TMP" ] && [ -d "$TEST_DIR_TMP" ]; then
    cd /tmp
    rm -rf "$TEST_DIR_TMP"
  fi
}

@test "ll script exists and is executable" {
  [ -f "$LL_SCRIPT" ]
  [ -x "$LL_SCRIPT" ]
}

@test "ll script runs without errors on current directory" {
  run "$LL_SCRIPT" .
  assert_success
}

@test "ll script produces output" {
  run "$LL_SCRIPT" .
  assert_success
  [ -n "$output" ]
}

@test "ll script handles -h option (human readable)" {
  run "$LL_SCRIPT" -h .
  assert_success
}

@test "ll script handles -l option (long format)" {
  run "$LL_SCRIPT" -l .
  assert_success
}

@test "ll script handles --help option" {
  run "$LL_SCRIPT" --help
  # Script may exit with 0 or show help
  [ $status -eq 0 ] || [ $status -eq 1 ]
}

@test "ll script handles --version option" {
  run "$LL_SCRIPT" --version
  # Script may exit with 0 or show version
  [ $status -eq 0 ] || [ $status -eq 1 ]
}

@test "ll script lists files in current directory" {
  run "$LL_SCRIPT" .
  assert_success
  # Should contain at least one of our test files
  assert_output --partial "test_file"
}

@test "ll script handles directory argument" {
  run "$LL_SCRIPT" test_dir1
  assert_success
}

@test "ll script handles -d option (list directories)" {
  run "$LL_SCRIPT" -d .
  assert_success
}

@test "ll script handles --directory option" {
  run "$LL_SCRIPT" --directory .
  assert_success
}

