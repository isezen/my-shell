# scripts/dev/ls-compare-canon-ls.pl
use strict;
use warnings;
use Time::Local qw(timegm);

my $now = $ENV{LS_COMPARE_NOW_EPOCH};
$now = time() if !defined($now) || $now !~ /^-?\d+$/;
my $u = $ENV{LS_COMPARE_USER};
my $has_human = $ENV{LS_COMPARE_HAS_HUMAN} // 0;
my $perms_re = qr/^(?:[bcdlps-])[rwxstST-]{9}[+.@]?$/;
my $blocks_re = qr/^[0-9]+(?:[.,][0-9]+)?[KMGTPBkmgptb]?$/;

my %mon_to_num = (
  Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5,
  Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11
);

sub parse_bsd_date {
  my ($mon_str, $day, $year_or_time) = @_;
  return undef unless defined($mon_str) && defined($day) && defined($year_or_time);
  
  my $mon = $mon_to_num{$mon_str};
  return undef unless defined($mon);
  
  my ($year, $hour, $min);
  if ($year_or_time =~ /^(\d{1,2}):(\d{2})$/) {
    # Format: HH:MM (recent file, year missing)
    # Derive year from real system time, not from test's LS_COMPARE_NOW_EPOCH,
    # because BSD ls uses current year for files modified within ~6 months.
    $hour = int($1);
    $min = int($2);
    my @sys_parts = gmtime(time());
    $year = $sys_parts[5] + 1900;
  } elsif ($year_or_time =~ /^(\d{4})$/) {
    # Format: YYYY (old file, time is 00:00)
    $year = int($1);
    $hour = 0;
    $min = 0;
  } else {
    return undef;
  }
  
  my $epoch = eval { timegm(0, $min, $hour, int($day), $mon, $year) };
  return $epoch;
}

sub rel_parts {
  my ($epoch) = @_;
  return ("", $epoch, "") if !defined($epoch) || $epoch !~ /^-?\d+$/;
  my $delta = $now - $epoch;
  my $prefix = "";
  if ($delta < 0) { $prefix = "in"; $delta = -$delta; }
  if ($delta < 120) { return ($prefix, $delta, "sec"); }
  if ($delta < 3600) { return ($prefix, int($delta/60), "min"); }
  if ($delta < 172800) { return ($prefix, int($delta/3600), "hrs"); }
  if ($delta < 3888000) { return ($prefix, int($delta/86400), "day"); }
  if ($delta < 31536000) { return ($prefix, int($delta/2592000), "mon"); }
  return ($prefix, int($delta/31536000), "yr");
}

sub quote_if_needed {
  my ($s) = @_;
  return $s if !defined($s);
  return (index($s, " ") >= 0 || index($s, "\t") >= 0) ? "\"$s\"" : $s;
}

sub lpad {
  my ($s, $w) = @_;
  my $len = length($s);
  return $s if $len >= $w;
  return (" " x ($w - $len)) . $s;
}

sub rpad {
  my ($s, $w) = @_;
  my $len = length($s);
  return $s if $len >= $w;
  return $s . (" " x ($w - $len));
}

sub format_tail {
  my ($tail, $perms) = @_;
  return "" if !defined($tail) || $tail eq "";
  # Remove only the first separator space/tab between date and filename
  # Preserve any leading whitespace that's part of the actual filename
  $tail =~ s/^[ \t]//;
  return "" if $tail eq "";

  if (defined($perms) && $perms =~ /^l/ && index($tail, " -> ") > 0) {
    my ($name, $target) = split(/ -> /, $tail, 2);
    $name = quote_if_needed($name);
    $target = quote_if_needed($target);
    return " $name -> $target";
  }

  $tail = quote_if_needed($tail);
  return " $tail";
}

my @lines;
while (my $line = <STDIN>) {
  $_ = $line;

  if (defined($u) && length($u)) {
    s/(?<!\S)\Q$u\E(?!\S)/you/g;
  }

  chomp;
  s/[ \t]+$//;
  push @lines, $_;
}

my @rows;
my $any_future = 0;
my $w_tnum = 0;
my $w_tunit = 0;
for my $line (@lines) {
  my $work = $line;
  my @epoch_matches;
  while ($work =~ /[\t ]([0-9]{9,})[\t ]/g) {
    push @epoch_matches, { s => $-[1], e => $+[1], epoch => $1 };
  }

  if (!@epoch_matches) {
    # Try parsing BSD ls -l date format: perms links owner group size Mon DD YYYY|HH:MM name
    # Tokenize the line and look for date pattern
    my @toks = split(/\s+/, $work);
    my $epoch_from_bsd = undef;
    my $date_start_idx = -1;
    my $date_end_pos = -1;
    
    # Find size field (should be numeric after group), then Mon DD YYYY|HH:MM
    for (my $i = 0; $i < @toks - 3; $i++) {
      if ($toks[$i] =~ /^\d+$/ && 
          exists($mon_to_num{$toks[$i+1]}) && 
          $toks[$i+2] =~ /^\d+$/ &&
          ($toks[$i+3] =~ /^\d{4}$/ || $toks[$i+3] =~ /^\d{1,2}:\d{2}$/)) {
        $epoch_from_bsd = parse_bsd_date($toks[$i+1], $toks[$i+2], $toks[$i+3]);
        $date_start_idx = $i + 1;
        
        # Find end position of date field in original line
        my $pattern = quotemeta($toks[$i]) . "\\s+" . quotemeta($toks[$i+1]) . "\\s+" . quotemeta($toks[$i+2]) . "\\s+" . quotemeta($toks[$i+3]);
        if ($work =~ /$pattern/) {
          $date_end_pos = $+[0];
        }
        last;
      }
    }
    
    if (defined($epoch_from_bsd) && $date_end_pos > 0) {
      # Extract tail from original line (preserves leading whitespace)
      my $tail = substr($work, $date_end_pos);
      
      my @prefix_toks = @toks[0..$date_start_idx-1];
      my $perms = $prefix_toks[0] // "";
      if ($perms_re && $perms =~ $perms_re) {
        $perms =~ s/[@+]$//;
        $prefix_toks[0] = $perms;
      }
      
      if ($has_human && $prefix_toks[-1] =~ /^\d+$/) {
        $prefix_toks[-1] = $prefix_toks[-1] . "B";
      }
      
      my ($tprefix, $tnum, $tunit) = rel_parts($epoch_from_bsd);
      $any_future = 1 if $tprefix eq "in";
      $w_tnum = length("$tnum") if length("$tnum") > $w_tnum;
      $w_tunit = length($tunit) if length($tunit) > $w_tunit;
      
      push @rows, {
        has_epoch => 1,
        toks => \@prefix_toks,
        tail => $tail,
        time_prefix => $tprefix,
        time_num => $tnum,
        time_unit => $tunit,
        perms => $perms,
      };
      next;
    }
    
    # No epoch and no BSD date pattern: keep raw
    push @rows, { has_epoch => 0, raw => $line };
    next;
  }

  my $m = $epoch_matches[-1];
  my $prefix = substr($work, 0, $m->{s});
  my $tail = substr($work, $m->{e});
  $prefix =~ s/^[ \t]+//;
  $prefix =~ s/[ \t]+$//;

  my @toks = length($prefix) ? split(/\s+/, $prefix) : ();
  if (!@toks) {
    push @rows, { has_epoch => 0, raw => $line };
    next;
  }

  # Normalize permission field: strip trailing @ or + (BSD extended attributes)
  if ($perms_re && $toks[0] =~ $perms_re) {
    $toks[0] =~ s/[@+]$//;
  }

  if ($has_human && $toks[-1] =~ /^\d+$/) { $toks[-1] = $toks[-1] . "B"; }

  my ($tprefix, $tnum, $tunit) = rel_parts($m->{epoch});
  $any_future = 1 if $tprefix eq "in";
  $w_tnum = length("$tnum") if length("$tnum") > $w_tnum;
  $w_tunit = length($tunit) if length($tunit) > $w_tunit;

  my $perm_idx = 0;
  if (@toks >= 2 && $toks[0] !~ $perms_re && $toks[0] =~ $blocks_re) {
    $perm_idx = 1;
  }
  my $perms = $toks[$perm_idx] // "";

  push @rows, {
    has_epoch => 1,
    toks => \@toks,
    tail => $tail,
    time_prefix => $tprefix,
    time_num => $tnum,
    time_unit => $tunit,
    perms => $perms,
  };
}

for my $r (@rows) {
  if (!$r->{has_epoch}) {
    print $r->{raw}, "\n";
    next;
  }

  my @toks = @{$r->{toks}};
  my $num_s = "$r->{time_num}";
  my $unit_s = rpad($r->{time_unit}, $w_tunit);
  my $value_width = $any_future ? ($w_tnum + 3) : $w_tnum;
  my $value_core = ($r->{time_prefix} eq "in") ? "in $num_s" : $num_s;
  my $value_field = lpad($value_core, $value_width);
  my $time = "$value_field $unit_s";

  my $tail_out = format_tail($r->{tail}, $r->{perms});
  print join(" ", @toks, $time) . $tail_out . "\n";
}
