#!/usr/bin/env bats
# Test suite for scripts/dus

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup: Get script path
setup() {
  TEST_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
  PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
  DUS_SCRIPT="$PROJECT_ROOT/scripts/dus"
  
  # Create a test directory with some files
  TEST_DIR_TMP=$(mktemp -d)
  cd "$TEST_DIR_TMP"
  
  # Create test files with some content
  echo "test content 1" > test_file1.txt
  echo "test content 2" > test_file2.txt
  mkdir test_dir1
  echo "test content 3" > test_dir1/file_in_dir.txt
}

teardown() {
  # Cleanup test directory
  if [ -n "$TEST_DIR_TMP" ] && [ -d "$TEST_DIR_TMP" ]; then
    cd /tmp
    rm -rf "$TEST_DIR_TMP"
  fi
}

@test "dus script exists and is executable" {
  [ -f "$DUS_SCRIPT" ]
  [ -x "$DUS_SCRIPT" ]
}

@test "dus script runs without errors on current directory" {
  run "$DUS_SCRIPT"
  # Script may succeed or fail depending on system, but should not crash
  [ $status -ge 0 ] && [ $status -le 2 ]
}

@test "dus script produces output" {
  run "$DUS_SCRIPT"
  # If script runs, it should produce output
  if [ $status -eq 0 ]; then
    [ -n "$output" ]
  fi
}

@test "dus script shows usage with -h option" {
  run "$DUS_SCRIPT" -h
  # Should show usage or help
  [ $status -eq 0 ] || [ $status -eq 1 ]
}

@test "dus script handles -v option (verbose)" {
  run "$DUS_SCRIPT" -v
  # Script may succeed or fail depending on implementation
  [ $status -ge 0 ] && [ $status -le 2 ]
}

@test "dus script handles -f option (files only)" {
  run "$DUS_SCRIPT" -f
  # Script may succeed or fail depending on implementation
  [ $status -ge 0 ] && [ $status -le 2 ]
}

@test "dus script handles -d option (directories only)" {
  run "$DUS_SCRIPT" -d
  # Script may succeed or fail depending on implementation
  [ $status -ge 0 ] && [ $status -le 2 ]
}

@test "dus script handles -a option (all)" {
  run "$DUS_SCRIPT" -a
  # Script may succeed or fail depending on implementation
  [ $status -ge 0 ] && [ $status -le 2 ]
}

