# tests/test_helper/ll-fixtures.bash
#
# Shared fixture helpers for the BATS ll_linux / ll_macos suites.
# Sourced from both tests/ll_macos/00_harness.bash and
# tests/ll_linux/00_harness.bash so that the epoch→mtime conversion
# logic lives in exactly one place.
#
# Background: before P3 #12, ll_macos's harness defined its own
# ll_epoch_to_touch_ts / ll_touch_epoch pair (BSD-flavored, using
# /bin/date -r + /usr/bin/touch -t), and ll_linux tests used a
# separate inline `"${LL_GNU_TOUCH}" -d "@${epoch}"` pattern. Both
# approaches solved the same problem on their respective platforms
# but shared no code. The functions here unify the strategies so a
# future test on either platform can just call ll_touch_epoch.
#
# ll_linux's existing LL_GNU_TOUCH/LL_GNU_DATE globals and their
# ~15 inline call sites in 30_edge.bats / 40_color.bats are left
# untouched — migrating them is a separate, larger refactor that
# would touch several bats files and gain only cosmetic uniformity.

# ll_touch_epoch <path> <epoch>
#   Set <path>'s mtime to <epoch> (unix seconds). Tries the available
#   userland combinations in order of preference:
#     1. GNU `touch -d "@<epoch>"`                    (native Linux,
#                                                      macOS+gnubin)
#     2. BSD `/bin/date -r` → format → `/usr/bin/touch -t`
#                                                     (pure macOS)
#     3. gdate/gtouch on non-standard paths           (fallback)
#   Returns 0 on success, 1 if no combination works.
ll_touch_epoch() {
  local path="$1"
  local epoch="$2"
  local ts

  # 1) GNU touch — single call, fastest, covers native Linux and
  #    any macOS with coreutils in PATH. The probe IS the apply:
  #    if touch succeeds, the mtime is already set.
  if touch -d "@${epoch}" "$path" 2>/dev/null; then
    return 0
  fi

  # 2) BSD path — /bin/date to format the epoch as the string that
  #    /usr/bin/touch -t expects, then apply in a second call.
  if /bin/date -r "$epoch" +%Y%m%d%H%M.%S >/dev/null 2>&1; then
    ts="$(/bin/date -r "$epoch" +%Y%m%d%H%M.%S)"
    /usr/bin/touch -t "$ts" "$path" && return 0
  fi

  # 3) gtouch if it exists somewhere other than PATH's `touch`.
  if command -v gtouch >/dev/null 2>&1; then
    gtouch -d "@${epoch}" "$path" && return 0
  fi

  # 4) gdate + BSD touch -t (Homebrew coreutils installed but gnubin
  #    not prepended to PATH).
  if command -v gdate >/dev/null 2>&1; then
    ts="$(gdate -d "@${epoch}" +%Y%m%d%H%M.%S)"
    if command -v /usr/bin/touch >/dev/null 2>&1; then
      /usr/bin/touch -t "$ts" "$path" && return 0
    fi
  fi

  return 1
}

# ll_epoch_to_touch_ts <epoch>
#   Print a BSD `touch -t` compatible timestamp (YYYYMMDDhhmm.SS) on
#   stdout, for the rare caller that needs the formatted string
#   without actually setting a file's mtime. Both ll_macos and any
#   future caller can rely on this API.
ll_epoch_to_touch_ts() {
  local epoch="$1"
  if /bin/date -r "$epoch" +%Y%m%d%H%M.%S 2>/dev/null; then
    return 0
  fi
  if command -v gdate >/dev/null 2>&1; then
    gdate -d "@${epoch}" +%Y%m%d%H%M.%S
    return 0
  fi
  return 1
}
