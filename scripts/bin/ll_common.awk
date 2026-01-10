###############################################################################
# ll_common.awk
#
# Common AWK "render library" for ll_linux and ll_macos.
#
# Purpose
# -------
# This file centralizes shared rendering utilities used by platform-specific
# ll implementations:
#   - ANSI SGR helpers and consistent reset handling
#   - padding helpers that are safe with ANSI-colored strings
#   - quoting rules (spaces/tabs)
#   - permission coloring
#   - numeric and human size coloring helpers
#   - relative time bucketing and coloring
#
# Design constraints
# ------------------
# - Must run on macOS /usr/bin/awk (BSD awk) and GNU awk (gawk).
# - Therefore: avoid gawk-only extensions in common functions.
# - No nested function definitions (BSD awk limitation).
#
# Integration pattern
# -------------------
# From bash:
#   awk -f /path/to/ll_common.awk -v ... -f - <<'AWK'
#     # main program here (platform-specific)
#   AWK
#
###############################################################################

# ----------------------------
# Global defaults / constants
# ----------------------------

# Document-level: ANSI escape and reset.
# NOTE: main program is free to override these vars (same names) after BEGIN.
function llc_init_ansi(    esc) {
  # Function docstring:
  #   Initialize ANSI escape and reset strings.
  #   Caller should run this early (BEGIN) if it relies on creset.
  esc = sprintf("%c", 27)
  llc_esc   = esc
  llc_creset = esc "[0m"
}

# Document-level: time bucket thresholds (seconds).
function llc_init_time_constants() {
  # Function docstring:
  #   Initialize shared time bucket thresholds and default labels.
  llc_TIME_2MIN   = 120
  llc_TIME_HOUR   = 3600
  llc_TIME_2DAYS  = 172800
  llc_TIME_45DAYS = 3888000
  llc_TIME_YEAR   = 31536000
  llc_TIME_MIN    = 60
  llc_TIME_DAY    = 86400
  llc_TIME_30DAYS = 2592000

  llc_lsec = "sec"
  llc_lmin = "min"
  llc_lhrs = "hrs"
  llc_lday = "day"
  llc_lmon = "mon"
  llc_lyr  = "yr"
}

# Document-level: size thresholds (bytes).
function llc_init_size_constants() {
  # Function docstring:
  #   Initialize shared size thresholds in bytes.
  llc_SIZE_KB = 1024
  llc_SIZE_MB = 1048576
  llc_SIZE_GB = 1073741824
  llc_SIZE_TB = 1099511627776
}

# ----------------------------
# String helpers
# ----------------------------

function llc_strip_colors(s) {
  # Function docstring:
  #   Remove ANSI SGR sequences from a string so length calculations are accurate.
  gsub(/\033\[[0-9;]*m/, "", s)
  return s
}

function llc_lpad(s, w,    raw_len, n, out) {
  # Function docstring:
  #   Left-pad string 's' to visual width 'w' (ANSI sequences ignored).
  raw_len = length(llc_strip_colors(s))
  n = w - raw_len
  if (n <= 0) return s
  out = sprintf("%*s", n, "")
  return out s
}

function llc_rpad(s, w,    raw_len, n, out) {
  # Function docstring:
  #   Right-pad string 's' to visual width 'w' (ANSI sequences ignored).
  raw_len = length(llc_strip_colors(s))
  n = w - raw_len
  if (n <= 0) return s
  out = sprintf("%*s", n, "")
  return s out
}

function llc_quote_if_needed(s) {
  # Function docstring:
  #   Quote filename if it contains space or tab.
  if (index(s, " ") > 0 || index(s, "\t") > 0) return "\"" s "\""
  return s
}

# ----------------------------
# Permission rendering
# ----------------------------

function llc_color_perm(p,    i, ch, out) {
  # Function docstring:
  #   Colorize permission string. Requires the following globals (set by main):
  #     cd, cl, cr, cw, cx, cplus, creset
  #   If not set, output will degrade gracefully (no colors).
  out = ""
  for (i = 1; i <= length(p); i++) {
    ch = substr(p, i, 1)
    if      (ch == "d" && cd    != "") out = out cd ch llc_creset
    else if (ch == "l" && cl    != "") out = out cl ch llc_creset
    else if (ch == "r" && cr    != "") out = out cr ch llc_creset
    else if (ch == "w" && cw    != "") out = out cw ch llc_creset
    else if (ch == "x" && cx    != "") out = out cx ch llc_creset
    else if (ch == "+" && cplus != "") out = out cplus ch llc_creset
    else out = out ch
  }
  return out
}

# ----------------------------
# Size rendering
# ----------------------------

function llc_size_color_numeric(bytes) {
  # Function docstring:
  #   Return a color SGR for numeric size tiers. Requires globals cb/ck/cm/cg/ct.
  if (bytes < llc_SIZE_KB) return cb
  if (bytes < llc_SIZE_MB) return ck
  if (bytes < llc_SIZE_GB) return cm
  if (bytes < llc_SIZE_TB) return cg
  return ct
}

function llc_color_size_human(s,    num, suf, len) {
  # Function docstring:
  #   Colorize human-readable size label (e.g. 12K, 3.4M, 9G, 1T, 123B).
  #   Requires globals: cb/ck/cm/cg/ct and clB/clK/clM/clG/clT and llc_creset.
  if (s ~ /^[0-9]+$/) s = s "B"

  # Normalize suffix parsing: last char is suffix (K/M/G/T/B)
  len = length(s)
  suf = substr(s, len, 1)
  num = substr(s, 1, len - 1)

  if      (suf == "T") return ct num llc_creset clT suf llc_creset
  else if (suf == "G") return cg num llc_creset clG suf llc_creset
  else if (suf == "M") return cm num llc_creset clM suf llc_creset
  else if (suf == "K" || suf == "k") return ck num llc_creset clK suf llc_creset
  else if (suf == "B") return cb num llc_creset clB suf llc_creset

  return cb s llc_creset
}

# ----------------------------
# Relative time rendering
# ----------------------------

function llc_time_calc(epoch, now_epoch,    dt, v, lbl, prefix) {
  # Function docstring:
  #   Compute relative time bucket from an epoch value.
  #
  # Inputs:
  #   epoch     : file mtime in seconds since epoch
  #   now_epoch : "now" in seconds since epoch (caller decides; may be systime())
  #
  # Outputs (globals):
  #   llc_time_future  : 1 if epoch is in the future, else 0
  #   llc_time_prefix  : "in" if future else ""
  #   llc_time_num     : bucket number
  #   llc_time_unit    : one of sec/min/hrs/day/mon/yr
  dt = int(now_epoch - (epoch + 0))
  if (dt < 0) { prefix = "in"; dt = -dt; llc_time_future = 1 }
  else { prefix = ""; llc_time_future = 0 }

  if      (dt < llc_TIME_2MIN)   { v = dt;                        lbl = llc_lsec }
  else if (dt < llc_TIME_HOUR)   { v = int(dt / llc_TIME_MIN);    lbl = llc_lmin }
  else if (dt < llc_TIME_2DAYS)  { v = int(dt / llc_TIME_HOUR);   lbl = llc_lhrs }
  else if (dt < llc_TIME_45DAYS) { v = int(dt / llc_TIME_DAY);    lbl = llc_lday }
  else if (dt < llc_TIME_YEAR)   { v = int(dt / llc_TIME_30DAYS); lbl = llc_lmon }
  else                           { v = int(dt / llc_TIME_YEAR);   lbl = llc_lyr  }

  llc_time_prefix = prefix
  llc_time_num = v
  llc_time_unit = lbl
}

function llc_color_reltime(field, unit, is_future) {
  # Function docstring:
  #   Colorize a pre-formatted relative time field according to its unit.
  #   Requires globals: csec/cmin/chrs/cday/cmon/cyr/cfut and llc_creset.
  if (is_future) return cfut field llc_creset
  if (unit == llc_lsec) return csec field llc_creset
  if (unit == llc_lmin) return cmin field llc_creset
  if (unit == llc_lhrs) return chrs field llc_creset
  if (unit == llc_lday) return cday field llc_creset
  if (unit == llc_lmon) return cmon field llc_creset
  if (unit == llc_lyr ) return cyr  field llc_creset
  return field
}