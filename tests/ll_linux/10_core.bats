#!/usr/bin/env bats
# Core option comparisons for scripts/bin/ll

load '../test_helper/bats-support/load'
load '../test_helper/bats-assert/load'
load './00_harness.bash'

@test "ll core: flag matrix (144 combinations)" {
  local -a dir_variants
  local -a block_variants
  local -a human_variants
  local -a numeric_variants
  local -a owner_variants
  local -a dir_tokens
  local -a block_tokens
  local -a human_tokens
  local -a numeric_tokens
  local -a owner_tokens
  local -a args
  local -a perms
  local dir_ref
  local block_ref
  local human_ref
  local numeric_ref
  local owner_ref
  local count
  local verbose
  verbose="${LL_MATRIX_VERBOSE:-${LL_MATRIX_VERBOSE:-0}}"

  dir_variants=("" "-d" "-d .")
  block_variants=("" "-s")
  human_variants=("" "-h" "--si")
  numeric_variants=("" "-n")
  owner_variants=("" "-g" "-G" "-g -G")

  ll_mk_testdir
  ll_seed_fixtures_common

  count=0
  for dir_ref in "${dir_variants[@]}"; do
    for block_ref in "${block_variants[@]}"; do
      for human_ref in "${human_variants[@]}"; do
        for numeric_ref in "${numeric_variants[@]}"; do
          for owner_ref in "${owner_variants[@]}"; do
            args=()

            [ -n "$dir_ref" ]     && read -r -a dir_tokens     <<<"$dir_ref"     || dir_tokens=()
            [ -n "$block_ref" ]   && read -r -a block_tokens   <<<"$block_ref"   || block_tokens=()
            [ -n "$human_ref" ]   && read -r -a human_tokens   <<<"$human_ref"   || human_tokens=()
            [ -n "$numeric_ref" ] && read -r -a numeric_tokens <<<"$numeric_ref" || numeric_tokens=()
            [ -n "$owner_ref" ]   && read -r -a owner_tokens   <<<"$owner_ref"   || owner_tokens=()

            args+=("${dir_tokens[@]}")
            args+=("${block_tokens[@]}")
            args+=("${human_tokens[@]}")
            args+=("${numeric_tokens[@]}")
            args+=("${owner_tokens[@]}")

            count=$((count + 1))
            if [ "$verbose" = "1" ]; then
              printf 'matrix combo #%s: %s\n' "$count" "${args[*]}" >&3
            fi
            ll_assert_canon_equal "${args[@]}"
          done
        done
      done
    done
  done

  # Alias sanity checks (keep these out of the matrix to avoid combinatorial blow-up).
  perms=(--directory)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #alias-1: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(--numeric-uid-gid)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #alias-2: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(--no-group)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #alias-3: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=()
  perms=(-n -s --si -g)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #perm-1: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(--si -s -n -g)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #perm-2: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(. -n -s --si -g)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #perm-3: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(file1.txt -h -n)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #perm-4: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(-d . -n --si -G)
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #perm-5: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(-n -s --si -g -- "a b.txt")
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #perm-6: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  perms=(--directory -n --no-group -- "a b.txt")
  if [ "$verbose" = "1" ]; then
    printf 'matrix combo #perm-7: %s\n' "${perms[*]}" >&3
  fi
  ll_assert_canon_equal "${perms[@]}"

  ll_rm_testdir
}

