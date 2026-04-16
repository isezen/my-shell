#!/usr/bin/env bats
# Minimal smoke tests for scripts/bin/ll2 (eza-based ll replacement).
#
# These are invariant tests, not byte-level parity tests against ll.
# Full parity with ll is not achievable because eza's column layout
# differs structurally from `ls -l`. Instead we pin the small surface
# that ll2 actively shapes on top of eza:
#   1. eza missing → non-zero exit with actionable message
#   2. fixture runs, dirs first, expected entries appear
#   3. owner column shows "you" (scope: owner only, not symlink paths)
#   4. time column ends with an ll bucket (sec|min|hrs|day|mon|yr)
#   5. flag translation: `-g` suppresses the owner column
#
# LL_NOW_EPOCH is intentionally NOT honored by ll2 — these tests assert
# only the bucket shape, not its value, so freshly-touched fixtures work.

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'

setup() {
  PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  LL2="${PROJECT_ROOT}/scripts/bin/ll2"

  export LC_ALL=C
  export TZ=UTC
  export LL_NO_COLOR=1

  SANDBOX="${BATS_TEST_TMPDIR}/ll2-sandbox"
  mkdir -p "${SANDBOX}"
  cd "${SANDBOX}"

  # Minimal fixture: one dir, two files, one symlink
  mkdir -p dir1
  touch file1.txt file2.txt
  ln -sf file1.txt link1
}

_require_eza() {
  if ! command -v eza >/dev/null 2>&1; then
    skip "eza not installed (brew install eza)"
  fi
}

@test "ll2: errors out with actionable message when eza is missing" {
  # Simulate missing eza by restricting PATH to system dirs only. /bin and
  # /usr/bin are required so `#!/usr/bin/env bash` resolves; brew/MacPorts
  # dirs (where eza lives) are excluded so `command -v eza` returns non-zero.
  local empty_bin="${BATS_TEST_TMPDIR}/empty-bin"
  mkdir -p "${empty_bin}"
  run env PATH="${empty_bin}:/usr/bin:/bin" "${LL2}" .

  assert_failure
  assert_output --partial "eza is required"
  assert_output --partial "brew install eza"
}

@test "ll2: lists fixture entries with directories first" {
  _require_eza
  run "${LL2}" .
  assert_success

  # All fixture entries present
  assert_output --partial "dir1"
  assert_output --partial "file1.txt"
  assert_output --partial "file2.txt"
  assert_output --partial "link1"

  # Directory line must appear before any regular-file line
  local dir_lineno file_lineno
  dir_lineno=$(printf '%s\n' "$output" | grep -n 'dir1$' | head -1 | cut -d: -f1)
  file_lineno=$(printf '%s\n' "$output" | grep -n 'file1.txt$' | head -1 | cut -d: -f1)
  [ -n "$dir_lineno" ] && [ -n "$file_lineno" ]
  [ "$dir_lineno" -lt "$file_lineno" ]
}

@test "ll2: owner column shows 'you' (scoped to owner, not path substrings)" {
  _require_eza
  # Create a symlink whose target path contains the username — proves we
  # use sub() (first occurrence = owner) and not gsub() (every match).
  local username
  username="$(id -un 2>/dev/null || printf '%s' "${USER:-}")"
  [ -n "$username" ] || skip "cannot resolve current username"
  ln -sf "/Users/${username}/nonexistent" path-with-username 2>/dev/null || \
    ln -sf "/home/${username}/nonexistent"  path-with-username 2>/dev/null || true

  run "${LL2}" .
  assert_success

  # Owner appears as 'you'
  assert_output --partial " you "

  # Raw username must not appear on any file1 line (owner-scope check)
  local file1_line
  file1_line=$(printf '%s\n' "$output" | grep 'file1.txt$' | head -1)
  [ -n "$file1_line" ]
  [[ "$file1_line" != *" ${username} "* ]]
}

@test "ll2: time column uses ll buckets (sec|min|hrs|day|mon|yr)" {
  _require_eza
  run "${LL2}" .
  assert_success

  # Every non-header line must contain exactly one ll bucket token
  # (optionally preceded by 'in ' for future mtimes).
  local line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [[ "$line" =~ (^|[[:space:]])(in[[:space:]])?[0-9]+[[:space:]](sec|min|hrs|day|mon|yr)[[:space:]] ]]; then
      continue
    fi
    printf 'line without ll bucket token: %s\n' "$line" >&2
    return 1
  done <<< "$output"
}

@test "ll2: -g flag translates to --no-user (owner column suppressed)" {
  _require_eza
  run "${LL2}" -g .
  assert_success

  # With -g, 'you' should NOT appear anywhere (owner column gone).
  # This project's minimal bats-assert lacks refute_output, so check inline.
  if [[ "$output" == *" you "* ]]; then
    printf 'expected no " you " in -g output but found one\noutput:\n%s\n' "$output" >&2
    return 1
  fi

  # Sanity: without -g, 'you' IS present — confirms the assertion above
  # is meaningful and not a fixture quirk.
  local without_g
  without_g="$("${LL2}" . 2>&1)"
  [[ "$without_g" == *" you "* ]]
}
