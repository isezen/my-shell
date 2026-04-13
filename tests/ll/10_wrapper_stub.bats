#!/usr/bin/env bats
# Wrapper contract tests for scripts/bin/ll (stub-based, platform-independent)

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  # Create an isolated sandbox per test.
  SANDBOX_DIR="${BATS_TEST_TMPDIR}/ll-wrapper-sandbox"
  mkdir -p "${SANDBOX_DIR}"

  # Copy the real wrapper into the sandbox so it dispatches to sandbox stubs.
  cp "${BATS_TEST_DIRNAME}/../../scripts/bin/ll" "${SANDBOX_DIR}/ll"
  chmod +x "${SANDBOX_DIR}/ll"

  # Create sandbox impl stubs as ll_linux and ll_macos.
  cp "${BATS_TEST_DIRNAME}/fixtures/ll_stub_impl.bash" "${SANDBOX_DIR}/ll_linux"
  cp "${BATS_TEST_DIRNAME}/fixtures/ll_stub_impl.bash" "${SANDBOX_DIR}/ll_macos"
  chmod +x "${SANDBOX_DIR}/ll_linux" "${SANDBOX_DIR}/ll_macos"
}

@test "ll wrapper: LL_IMPL_PATH wins and forwards argv verbatim" {
  run env \
    STUB_ROLE=impl_path \
    LL_IMPL_PATH="${SANDBOX_DIR}/ll_linux" \
    "${SANDBOX_DIR}/ll" -- -n "a b.txt" $'a\tb.txt'

  assert_success
  assert_line --partial 'STUB_ROLE=impl_path'
  assert_line --partial 'ARGV_COUNT=4'
  assert_line --partial 'ARGV_01=--'
  assert_line --partial 'ARGV_02=-n'
  assert_line --partial 'ARGV_03=a b.txt'
  assert_line --partial $'ARGV_04=a\tb.txt'
}

@test "ll wrapper: LL_IMPL=linux selects ll_linux in the same directory" {
  run env \
    STUB_ROLE=linux \
    LL_IMPL=linux \
    "${SANDBOX_DIR}/ll" -n

  assert_success
  assert_line --partial 'STUB_ROLE=linux'
  assert_line --partial 'ARGV_01=-n'
}

@test "ll wrapper: LL_IMPL=macos selects ll_macos in the same directory" {
  run env \
    STUB_ROLE=macos \
    LL_IMPL=macos \
    "${SANDBOX_DIR}/ll" -G

  assert_success
  assert_line --partial 'STUB_ROLE=macos'
  assert_line --partial 'ARGV_01=-G'
}

@test "ll wrapper: invalid LL_IMPL returns exit 2" {
  run env \
    LL_IMPL=badvalue \
    "${SANDBOX_DIR}/ll"

  assert_failure
  [ "$status" -eq 2 ]
}

@test "ll wrapper: LL_SCRIPT recursion guard does not exec itself" {
  # If LL_SCRIPT points to the wrapper itself, it must be ignored.
  # We force a known execution path via LL_IMPL=linux and verify the stub ran.
  run env \
    STUB_ROLE=linux \
    LL_SCRIPT="${SANDBOX_DIR}/ll" \
    LL_IMPL=linux \
    "${SANDBOX_DIR}/ll" -d

  assert_success
  assert_line --partial 'STUB_ROLE=linux'
  assert_line --partial 'ARGV_01=-d'
}

@test "ll wrapper: LL_SCRIPT set but not executable returns exit 1 and error" {
  touch "${SANDBOX_DIR}/not_exec_script"
  run env \
    LL_SCRIPT="${SANDBOX_DIR}/not_exec_script" \
    "${SANDBOX_DIR}/ll"
  assert_failure
  [ "$status" -eq 1 ]
  assert_output --partial "LL_SCRIPT is set but not executable"
}

@test "ll wrapper: LL_IMPL_PATH set but not executable returns exit 1 and error" {
  touch "${SANDBOX_DIR}/not_exec_impl"
  run env \
    LL_IMPL_PATH="${SANDBOX_DIR}/not_exec_impl" \
    "${SANDBOX_DIR}/ll"
  assert_failure
  [ "$status" -eq 1 ]
  assert_output --partial "LL_IMPL_PATH is set but not executable"
}
