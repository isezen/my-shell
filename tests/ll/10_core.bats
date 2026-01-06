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

  declare -a dir_var0=()
  declare -a dir_var1=(-d)
  declare -a dir_var2=(-d .)
  dir_variants=(dir_var0 dir_var1 dir_var2)

  declare -a block_var0=()
  declare -a block_var1=(-s)
  block_variants=(block_var0 block_var1)

  declare -a human_var0=()
  declare -a human_var1=(-h)
  declare -a human_var2=(--si)
  human_variants=(human_var0 human_var1 human_var2)

  declare -a numeric_var0=()
  declare -a numeric_var1=(-n)
  numeric_variants=(numeric_var0 numeric_var1)

  declare -a owner_var0=()
  declare -a owner_var1=(-g)
  declare -a owner_var2=(-G)
  declare -a owner_var3=(-g -G)
  owner_variants=(owner_var0 owner_var1 owner_var2 owner_var3)

  ll_mk_testdir
  ll_seed_fixtures_common

  count=0
  for dir_ref in "${dir_variants[@]}"; do
    eval "dir_tokens=(\"\${${dir_ref}[@]}\")"
    for block_ref in "${block_variants[@]}"; do
      eval "block_tokens=(\"\${${block_ref}[@]}\")"
      for human_ref in "${human_variants[@]}"; do
        eval "human_tokens=(\"\${${human_ref}[@]}\")"
        for numeric_ref in "${numeric_variants[@]}"; do
          eval "numeric_tokens=(\"\${${numeric_ref}[@]}\")"
          for owner_ref in "${owner_variants[@]}"; do
            eval "owner_tokens=(\"\${${owner_ref}[@]}\")"
            args=()
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
