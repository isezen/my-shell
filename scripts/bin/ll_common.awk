###############################################################################
# scripts/bin/ll_common.awk
# Shared awk helpers for ll_* implementations (macOS + linux).
# BSD awk compatible (no nested function defs, no gawk-only features).
#
# Expected vars (passed via -v):
#   DEC_SEP, USERNAME, NUMERIC, NOW_EPOCH, SI
#   (optional) ENVIRON["LS_COLORS"]
#
# Provides:
#   ll_common_init()
#   plus many helper functions used by ll_macos drivers.

function max(a,b){ return (a>b)?a:b }
function sp(n){ if (n<=0) return ""; return sprintf("%*s", n, "") }

function _trim(s){
  sub(/^[ \t]+/, "", s)
  sub(/[ \t]+$/, "", s)
  return s
}

# ----------------------------
# Robust LS_COLORS parser
# - Handles escaped ":" and "=" (e.g. "\\:" "\\=")
# - Splits on unescaped ":" into tokens "key=value"
# ----------------------------
function _ls_process_token(tok,   eq, k, v, suf){
  if (tok == "") return
  eq = index(tok, "=")
  if (eq <= 0) return
  k = _trim(substr(tok, 1, eq-1))
  v = _trim(substr(tok, eq+1))

  if (k == "di") COL_DI = v
  else if (k == "ln") {
    # ignore ln=target for ll_linux test parity
    if (v != "target") COL_LN = v
  }
  else if (k == "su") COL_SU = v
  else if (k == "sg") COL_SG = v
  else if (k == "pi") COL_PI = v
  else if (k == "so") COL_SO = v
  else if (k == "ex") COL_EX = v
  else if (k == "fi") COL_FI = v
  else if (k == "or") COL_OR = v
  else if (k == "ow") COL_OW = v
  else if (k == "tw") COL_TW = v
  else if (k == "st") COL_ST = v
  else if (k ~ /^\*/) {
    suf = substr(k, 2)
    ext_lastcol[suf] = v
    ext_has_len[length(suf)] = 1
  }
}

function parse_ls_colors(s,   i, c, tok){
  tok = ""
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (c == "\\") {
      if (i < length(s)) { tok = tok substr(s, i+1, 1); i++ }
      else tok = tok c
    } else if (c == ":") {
      _ls_process_token(tok)
      tok = ""
    } else {
      tok = tok c
    }
  }
  _ls_process_token(tok)
}

# Build a descending-sorted list of unique suffix lengths from ext_has_len[].
function build_ext_lens(   k, n, i, j, tmp){
  n = 0
  for (k in ext_has_len) {
    n++
    ext_lens[n] = k + 0
  }
  for (i = 2; i <= n; i++) {
    tmp = ext_lens[i]
    j = i - 1
    while (j >= 1 && ext_lens[j] < tmp) {
      ext_lens[j+1] = ext_lens[j]
      j--
    }
    ext_lens[j+1] = tmp
  }
  n_extlen = n
}

# Safe double-quote shell quoting for passing filenames to /bin/sh.
function sh_dquote(s,   t){
  t = s
  gsub(/[\\"$`]/, "\\\\&", t)
  return "\"" t "\""
}

function llc_quote_if_needed(s){
  if (index(s, " ")>0 || index(s, "\t")>0) return "\"" s "\""
  return s
}

function ttype_from_perms(p,   first){
  if (p == "") return "O"
  first = substr(p, 1, 1)
  if (first == "d") return "D"
  if (p ~ /x/) return "X"
  return "F"
}

function orphan_color(   color){
  color = COL_OR
  if (color == "") color = COL_OR_DEFAULT
  if (color == "") return ""
  return esc "[" color "m"
}

function color_for_name(name, perms,   base, col, ux, gx, owrite, sticky, j, L, suf){
  ux = substr(perms, 4, 1)
  gx = substr(perms, 7, 1)
  if ((ux == "s" || ux == "S") && COL_SU != "") return esc "[" COL_SU "m"
  if ((gx == "s" || gx == "S") && COL_SG != "") return esc "[" COL_SG "m"

  if (perms ~ /^d/) {
    # Match ll_linux/test-suite behavior:
    # If directory is sticky (t/T), ALWAYS use "tw" (ignore "st"),
    # even when other-writable is also set.
    owrite = (substr(perms, 9, 1) == "w")
    sticky = (substr(perms,10,1) == "t" || substr(perms,10,1) == "T")
    if (sticky && COL_TW != "") return esc "[" COL_TW "m"
    if (!sticky && owrite && COL_OW != "") return esc "[" COL_OW "m"
    base = COL_DI
  }
  else if (perms ~ /^l/) base = COL_LN
  else if (perms ~ /^p/) base = COL_PI
  else if (perms ~ /^s/) base = COL_SO
  else if (perms ~ /x/)  base = COL_EX
  else base = COL_FI

  col = ""
  if (base == COL_FI) {
    for (j = 1; j <= n_extlen; j++) {
      L = ext_lens[j]
      if (length(name) >= L) {
        suf = substr(name, length(name) - L + 1)
        if (suf in ext_lastcol) { col = ext_lastcol[suf]; break }
      }
    }
  }
  if (col != "") return esc "[" col "m"
  if (base == "0" || base == "") return ""
  return esc "[" base "m"
}

function symlink_link_color(name, target, target_type, target_perms,   color){
  if (target_type == "O") return orphan_color()
  if (target_type == "D" || target_type == "X") {
    if (target_perms != "") return color_for_name(target, target_perms)
    if (target_type == "D") return color_for_name(target, "d---------")
    return color_for_name(target, "-x------")
  }
  if (target_type == "F") {
    color = color_for_name(name, "----------")
    if (color != "") return color
    return ""
  }
  if (CSYMLINK != "") return CSYMLINK
  return ""
}

function symlink_target_color(target, target_type, target_perms){
  if (target_type == "O") return orphan_color()
  if (target_perms != "") return color_for_name(target, target_perms)
  if (target_type == "D") return color_for_name(target, "d---------")
  if (target_type == "X") return color_for_name(target, "-x------")
  return color_for_name(target, "----------")
}

function color_and_quote(value, color,   quoted){
  quoted = quote_if_needed(value)
  if (quoted != value) {
    if (color != "") return "\"" color value "\""
    return "\"" value "\""
  }
  if (color != "") return color value
  return value
}

function format_symlink(name, target, target_type, target_perms,   link_color, target_color, color_for_target, colored_name, colored_target, out){
  link_color = symlink_link_color(name, target, target_type, target_perms)
  target_color = symlink_target_color(target, target_type, target_perms)
  if (link_color != "") color_for_target = link_color
  else color_for_target = target_color
  colored_name = color_and_quote(name, link_color)
  colored_target = color_and_quote(target, color_for_target)
  out = colored_name " -> " colored_target
  if (link_color != "" || color_for_target != "") out = out creset
  return out
}

function format_name(name, perms, target, target_type, target_perms,   cname, q){
  if (perms ~ /^l/ && target != "") return format_symlink(name, target, target_type, target_perms)
  cname = color_for_name(name, perms)
  q = quote_if_needed(name)
  if (q != name) {
    if (cname != "") return "\"" cname name "\"" creset
    return "\"" name "\""
  }
  if (cname != "") return cname name creset
  return name
}

function llc_color_perm(p,   i, ch, out){
  if (p in perm_col_cache) return perm_col_cache[p]
  out = ""
  for (i=1; i<=length(p); i++) {
    ch = substr(p, i, 1)
    if (ch=="d") out = out cd ch creset
    else if (ch=="l") out = out cl ch creset
    else if (ch=="r") out = out cr ch creset
    else if (ch=="w") out = out cw ch creset
    else if (ch=="x") out = out cx ch creset
    else if (ch=="+") out = out cplus ch creset
    else out = out ch
  }
  perm_col_cache[p] = out
  return out
}

function size_color_numeric(x){
  if (x < 1024) return cb
  if (x < 1048576) return ck
  if (x < 1073741824) return cm
  if (x < 1099511627776) return cg
  return ct
}

function human_size(bytes,   scaled){
  if (bytes !~ /^[0-9]+$/) return bytes
  if (bytes < 1024) return bytes "B"
  if (bytes < 1048576) { scaled=sprintf("%.1f", bytes/1024.0); sub(/\.0$/,"",scaled); return scaled "K" }
  if (bytes < 1073741824) { scaled=sprintf("%.1f", bytes/1048576.0); sub(/\.0$/,"",scaled); return scaled "M" }
  if (bytes < 1099511627776) { scaled=sprintf("%.1f", bytes/1073741824.0); sub(/\.0$/,"",scaled); return scaled "G" }
  scaled=sprintf("%.1f", bytes/1099511627776.0); sub(/\.0$/,"",scaled); return scaled "T"
}

function color_size_human(s,   num, suf, len){
  if (s ~ /^[0-9]+$/) s = s "B"
  if (s ~ /^[0-9]+(\.[0-9]+)?[kKMGTTB]$/) {
    len = length(s)
    suf = substr(s, len, 1)
    num = substr(s, 1, len-1)
    if (suf=="T") return ct num creset clT suf creset
    if (suf=="G") return cg num creset clG suf creset
    if (suf=="M") return cm num creset clM suf creset
    if (suf=="K" || suf=="k") return ck num creset clK suf creset
    if (suf=="B") return cb num creset clB suf creset
  }
  return cb s creset
}

function blocks_human_label(blocks, si_mode,   bytes, base, unit, val){
  if (blocks !~ /^[0-9]+$/) return blocks
  bytes = blocks * 1024
  base = si_mode ? 1000 : 1024
  if (bytes < base) return "0B"
  if (bytes < base*base) {
    unit = si_mode ? "k" : "K"
    val = sprintf("%.1f", bytes/base)
    if (DEC_SEP != ".") gsub(/\./, DEC_SEP, val)
    return val unit
  }
  if (bytes < base*base*base) { val=sprintf("%.1f", bytes/(base*base)); if (DEC_SEP!=".") gsub(/\./,DEC_SEP,val); return val "M" }
  if (bytes < base*base*base*base) { val=sprintf("%.1f", bytes/(base*base*base)); if (DEC_SEP!=".") gsub(/\./,DEC_SEP,val); return val "G" }
  val=sprintf("%.1f", bytes/(base*base*base*base)); if (DEC_SEP!=".") gsub(/\./,DEC_SEP,val); return val "T"
}

function llc_color_reltime(s, unit, is_future){
  if (is_future) return cfut s creset
  if (unit=="sec") return csec s creset
  if (unit=="min") return cmin s creset
  if (unit=="hrs") return chrs s creset
  if (unit=="day") return cday s creset
  if (unit=="mon") return cmon s creset
  if (unit=="yr") return cyr s creset
  return s
}

function ll_common_init(){
  # Time/size constants must be initialized BEFORE the NO_COLOR early-return,
  # otherwise llc_time_calc() and llc_color_size_human() divide by zero.
  llc_init_size_constants()
  llc_init_time_constants()

  if (NO_COLOR == "1") {
    esc = ""
    creset = ""
    CSYMLINK = ""
    COL_DI = ""; COL_LN = ""; COL_SU = ""; COL_SG = ""; COL_PI = ""; COL_SO = ""; COL_EX = ""; COL_FI = ""
    COL_OR = ""; COL_OW = ""; COL_TW = ""; COL_ST = ""; COL_OR_DEFAULT = ""
    return
  }

  esc = sprintf("%c", 27)
  creset = esc "[0m"
  # ll_linux (GNU ls) style symlink SGR used by tests
  CSYMLINK = esc "[38;5;208;1m"

  # defaults (GNU-ish)
  COL_DI = "01;34"
  COL_LN = "01;36"
  COL_SU = ""
  COL_SG = ""
  COL_PI = ""
  COL_SO = ""
  COL_EX = "01;32"
  COL_FI = "0"
  COL_OR = ""
  COL_OW = ""
  COL_TW = ""
  COL_ST = ""
  COL_OR_DEFAULT = "48;5;196;38;5;232;1"

  delete ext_lastcol; delete ext_has_len; delete ext_lens
  n_extlen = 0

  if (ENVIRON["LS_COLORS"] != "") parse_ls_colors(ENVIRON["LS_COLORS"])
  build_ext_lens()

  cd    = esc "[38;5;122m"
  cl    = esc "[38;5;190m"
  cr    = esc "[38;5;119m"
  cw    = esc "[38;5;216m"
  cx    = esc "[38;5;124m"
  cplus = esc "[38;5;129m"

  cusr  = esc "[38;5;66m"
  croot = esc "[38;5;160m"

  cb = esc "[38;5;240m"
  ck = esc "[38;5;250m"
  cm = esc "[38;5;117m"
  cg = esc "[38;5;208m"
  ct = esc "[38;5;160m"

  clT = esc "[1;38;5;167m"
  clG = esc "[1;38;5;220m"
  clM = esc "[1;38;5;123m"
  clK = esc "[1;38;5;107m"
  clB = esc "[1;38;5;248m"

  csec = esc "[38;5;124m"
  cmin = esc "[38;5;215m"
  chrs = esc "[38;5;196m"
  cday = esc "[38;5;230m"
  cmon = esc "[38;5;151m"
  cyr  = esc "[38;5;241m"
  cfut = esc "[38;5;39m"

  delete perm_col_cache
  llc_init_ansi()
  # size/time constants already initialized above, before NO_COLOR early-return
}

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

function llc_strip_leading_resets(s) {
  # Function docstring:
  #   Strip redundant leading SGR reset sequences (e.g. GNU ls emits
  #   "\033[0m\033[0m..." chains).
  while (s ~ /^\033\[0m/) sub(/^\033\[0m/, "", s)
  return s
}

function llc_strip_trailing_resets(s) {
  # Function docstring:
  #   Strip redundant trailing SGR reset sequences.
  while (s ~ /\033\[0m$/) sub(/\033\[0m$/, "", s)
  return s
}

function llc_has_nonreset_sgr(s,    t) {
  # Function docstring:
  #   Return 1 if 's' contains at least one SGR sequence that is not a plain
  #   reset (\033[0m). Used to decide whether a rendered field actually
  #   carries color and therefore needs a trailing reset.
  t = s
  gsub(/\033\[0m/, "", t)
  return (t ~ /\033\[[0-9;]*m/)
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

# ----------------------------
# Permission rendering
# ----------------------------

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

# Wrapper functions for backward compatibility
function time_calc(epoch) {
  llc_time_calc(epoch, NOW_EPOCH)
  time_future = llc_time_future
  time_prefix = llc_time_prefix
  time_num = llc_time_num
  time_unit = llc_time_unit
}

function color_reltime(field, unit, is_future) {
  return llc_color_reltime(field, unit, is_future)
}

function color_perm(p) {
  return llc_color_perm(p)
}

function quote_if_needed(s) {
  return llc_quote_if_needed(s)
}
