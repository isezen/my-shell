###############################################################################
# scripts/bin/ll_linux.awk
# Linux-specific (GNU `ls -l` driven) ingress helpers for ll_linux.
#
# GAWK REQUIRED. ll_linux is gawk-only by design (see scripts/bin/ll_linux
# binary probing at lines ~199). Functions in this file may use gawk-only
# features like 3-argument match(). ll_common.awk, by contrast, MUST remain
# BSD awk compatible because ll_macos runs it under /usr/bin/awk.
#
# Responsibilities:
#   * Parse a GNU `ls --color -l --time-style=+%s` output line into record
#     fields (perms, links, owner, group, size, epoch, name) that the driver
#     loop can store and render.
#   * Render the (pre-colored) name+target string emitted by GNU ls into the
#     final ll_linux name column, preserving/cleaning ANSI resets and
#     re-quoting around the name.
#
# Globals consumed (driver awk -v):
#   ASIZE, OWNER, GROUPNAME
# Globals consumed (from ll_common.awk):
#   creset, llc_has_nonreset_sgr, llc_strip_leading_resets,
#   llc_strip_trailing_resets, llc_quote_if_needed
# Globals mutated by parse_line():
#   epoch, epoch_start, epoch_end, blocks, perms, links, owner, group, size, name
###############################################################################

# ---------------------------------------------------------------------------
# Epoch-anchored GNU `ls -l` line parser
# ---------------------------------------------------------------------------
# We force --time-style=+%s, so the mtime in the line is an epoch integer of
# 9+ digits surrounded by whitespace. We find that span first, extract the
# tail (filename + optional symlink target) as-is (preserving leading spaces,
# tabs, unicode, and symlink arrows), then tokenize the left side by
# whitespace to recover the fixed-field columns.
# ---------------------------------------------------------------------------

function _is_epoch(tok) {
  # Function docstring:
  #   Return 1 iff 'tok' looks like a GNU --time-style=+%s epoch (>=9 digits).
  return (tok ~ /^[0-9]{9,}$/)
}

function _find_epoch_span(line,   tmp, off, best_s, best_e, s, e, digits) {
  # Function docstring:
  #   Locate the LAST " <9+digits> " span in 'line' and populate globals
  #   epoch / epoch_start / epoch_end (inclusive). Returns 1 on success.
  #
  # GAWK NOTE: This function uses the 2-arg match() pattern form along with
  # RSTART/RLENGTH, which is portable. It does NOT use the gawk-only 3-arg
  # match(str, re, array) form, so it is safe to lift into BSD awk as-is if
  # ever needed. (Retained here because ll_linux is the only caller.)
  tmp = line
  off = 0
  best_s = 0
  best_e = 0

  while (match(tmp, /[[:space:]][0-9]{9,}[[:space:]]/)) {
    s = off + RSTART
    e = off + RSTART + RLENGTH - 1
    best_s = s
    best_e = e

    # Keep the trailing space so the next match can see the following digits.
    off = off + RSTART + RLENGTH - 2
    tmp = substr(line, off + 1)
  }

  if (best_s == 0) return 0

  digits = substr(line, best_s, best_e - best_s + 1)
  gsub(/^[[:space:]]+/, "", digits)
  gsub(/[[:space:]]+$/, "", digits)

  if (!_is_epoch(digits)) return 0

  epoch = digits
  epoch_start = best_s
  epoch_end = best_e
  return 1
}

function parse_line(line,   left, nlt, toks) {
  # Function docstring:
  #   Parse one GNU `ls -l` line into globals. Returns 1 on success, 0 on
  #   "skip this line" (total/toplam header, malformed, etc.).
  #
  # Globals written on success:
  #   blocks, perms, links, owner, group, size, epoch, name
  if (line ~ /^(total|toplam)[[:space:]]+/) return 0

  if (!_find_epoch_span(line)) return 0

  # Extract tail (filename + optional symlink target) RAW:
  # _find_epoch_span matches "<space><epoch><space>" so epoch_end points at
  # the trailing separator space. Everything from (epoch_end + 1) onwards is
  # the filename (plus optional " -> target" for symlinks), preserving
  # leading spaces, tabs, unicode and symlink arrows exactly as GNU ls
  # emitted them.
  name = substr(line, epoch_end + 1)

  # Left part: everything before the epoch span. Tokenize by whitespace.
  left = substr(line, 1, epoch_start - 1)
  gsub(/^[[:space:]]+/, "", left)

  nlt = split(left, toks, /[[:space:]]+/)
  if (nlt < 3) return 0

  if (ASIZE) {
    blocks = toks[1]
    perms  = toks[2]
    links  = toks[3]

    if (OWNER && GROUPNAME) {
      if (nlt < 6) return 0
      owner = toks[4]
      group = toks[5]
      size  = toks[nlt]
    } else if (!OWNER && GROUPNAME) {
      if (nlt < 5) return 0
      owner = ""
      group = toks[4]
      size  = toks[nlt]
    } else if (OWNER && !GROUPNAME) {
      if (nlt < 5) return 0
      owner = toks[4]
      group = ""
      size  = toks[nlt]
    } else {
      if (nlt < 3) return 0
      owner = ""
      group = ""
      size  = toks[nlt]
    }
  } else {
    blocks = ""
    perms  = toks[1]
    links  = toks[2]

    if (OWNER && GROUPNAME) {
      if (nlt < 5) return 0
      owner = toks[3]
      group = toks[4]
      size  = toks[nlt]
    } else if (!OWNER && GROUPNAME) {
      if (nlt < 4) return 0
      owner = ""
      group = toks[3]
      size  = toks[nlt]
    } else if (OWNER && !GROUPNAME) {
      if (nlt < 4) return 0
      owner = toks[3]
      group = ""
      size  = toks[nlt]
    } else {
      if (nlt < 2) return 0
      owner = ""
      group = ""
      size  = toks[nlt]
    }
  }

  return 1
}

# ---------------------------------------------------------------------------
# Name + symlink rendering for pre-colored GNU ls fields
# ---------------------------------------------------------------------------
# GNU `ls --color -l` emits the filename (and optional symlink target) with
# its own LS_COLORS-based SGR sequences already baked in. This function
# trusts those colors as-is; its job is purely to:
#   1) strip redundant leading/trailing resets that GNU ls adds,
#   2) split on " -> " if the perms indicate a symlink,
#   3) re-quote each component if it contains a space or tab,
#   4) append a trailing reset only when real (non-reset) SGR is present.
#
# This differs from ll_common.awk's 5-arg format_name(), which rebuilds
# colors from scratch using stat-derived metadata (what ll_macos feeds it).
# ---------------------------------------------------------------------------

function format_name_raw(raw, perms,   arrow_pos, n2, target, out, colored) {
  # Function docstring:
  #   Render the name column for ll_linux from the pre-colored GNU ls tail.
  #
  # Inputs:
  #   raw   : tail string (post-epoch) from the GNU ls -l line, with SGR.
  #   perms : permission string (first char "l" => symlink).
  #
  # Output:
  #   Final colored name (+ optional " -> target"), quoted if needed.
  raw = llc_strip_leading_resets(llc_strip_trailing_resets(raw))
  colored = llc_has_nonreset_sgr(raw)

  if (perms ~ /^l/ && (arrow_pos = index(raw, " -> ")) > 0) {
    n2 = substr(raw, 1, arrow_pos - 1)
    target = substr(raw, arrow_pos + 4)

    n2 = llc_strip_leading_resets(llc_strip_trailing_resets(n2))
    target = llc_strip_leading_resets(llc_strip_trailing_resets(target))

    # Drop residual resets if the component has no real (non-reset) SGR.
    if (!llc_has_nonreset_sgr(n2)) gsub(/\033\[0m/, "", n2)
    if (!llc_has_nonreset_sgr(target)) gsub(/\033\[0m/, "", target)

    out = llc_quote_if_needed(n2) " -> " llc_quote_if_needed(target)
    return colored ? (out creset) : out
  }

  if (!colored) gsub(/\033\[0m/, "", raw)
  out = llc_quote_if_needed(raw)
  return colored ? (out creset) : out
}
