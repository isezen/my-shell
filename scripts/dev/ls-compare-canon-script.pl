use strict;
use warnings;

my $u = $ENV{LS_COMPARE_USER};
my $unit_re = qr/(?:sec|min|hrs|hr|day|mon|mo|yr)/;
my $perms_re = qr/^(?:[bcdlps-])[rwxstST-]{9}[+.@]?$/;
my $blocks_re = qr/^[0-9]+(?:[.,][0-9]+)?[KMGTPBkmgptb]?$/;
my $has_human  = $ENV{LS_COMPARE_HAS_HUMAN}  // 0;
my $prefix_w = 2;
my $num_w = 2;

my $now = $ENV{LS_COMPARE_NOW_EPOCH};
$now = time() if !defined($now) || $now !~ /^-?\d+$/;

sub rel {
  my ($epoch) = @_;
  return $epoch if !defined($epoch) || $epoch !~ /^-?\d+$/;
  my $delta = $now - $epoch;
  my $prefix = "";
  if ($delta < 0) { $prefix = "in"; $delta = -$delta; }
  if ($delta < 120) { return fmt_rel($prefix, $delta, "sec"); }
  if ($delta < 3600) { return fmt_rel($prefix, int($delta/60), "min"); }
  if ($delta < 172800) { return fmt_rel($prefix, int($delta/3600), "hrs"); }
  if ($delta < 3888000) { return fmt_rel($prefix, int($delta/86400), "day"); }
  if ($delta < 31536000) { return fmt_rel($prefix, int($delta/2592000), "mon"); }
  return fmt_rel($prefix, int($delta/31536000), "yr");
}

sub fmt_rel {
  my ($prefix, $num, $unit) = @_;
  $unit = "hrs" if defined($unit) && $unit eq "hr";
  $unit = "mon" if defined($unit) && $unit eq "mo";
  return sprintf("%-*s %*d %s", $prefix_w, $prefix, $num_w, $num, $unit);
}

while (my $line = <STDIN>) {
  $_ = $line;

  if (defined($u) && length($u)) {
    s/(?<!\S)\Q$u\E(?!\S)/you/g;
  }

  s/[ \t]+$//;

  my $work = $_;
  chomp $work;
  $work =~ s/[ \t]+$//;

  # Drop ll-chatgpt single-file time-only helper lines.
  if ($work =~ /^\s*(?:\S+\s+)?(?:in\s+)?-?\d+\s+$unit_re\s*$/) {
    next;
  }

  my @candidates;
  while ($work =~ /[ \t]+(?:(in)[ \t]+)?(-?\d+)[ \t]+($unit_re)/g) {
    push @candidates, { s => $-[0], e => $+[0], prefix => $1, tn => $2, unit => $3 };
  }

  my $matched = 0;
  for (my $i = $#candidates; $i >= 0; $i--) {
    my $c = $candidates[$i];
    my $prefix = substr($work, 0, $c->{s});
    my $tail = substr($work, $c->{e});
    $prefix =~ s/^[ \t]+//;
    $prefix =~ s/[ \t]+$//;

    my @toks = length($prefix) ? split(/\s+/, $prefix) : ();
    next if @toks < 3;

    my $perm_idx = 0;
    if ($toks[0] !~ $perms_re && $toks[0] =~ $blocks_re && @toks >= 2) {
      $perm_idx = 1;
    }
    next if $toks[$perm_idx] !~ $perms_re;
    next if !defined $toks[$perm_idx + 1] || $toks[$perm_idx + 1] !~ /^\d+$/;

    if ($has_human && $perm_idx == 1 && $toks[0] =~ /^([0-9]+)B$/) {
      $toks[0] = $1;
    }

    if (@toks >= 2 && $toks[-1] =~ /^[0-9]{9,}$/ && $toks[-2] !~ /^[0-9]{9,}$/) {
      pop @toks;
    }

    my $tn = $c->{tn};
    my $time_prefix = $c->{prefix} // "";
    if (defined($tn) && $tn < 0) {
      $tn = -$tn;
      $time_prefix = "in";
    }
    my $rt = fmt_rel($time_prefix, $tn, $c->{unit});
    my @out = (@toks, $rt);
    $_ = join(" ", @out) . $tail . "\n";
    $matched = 1;
    last;
  }

  if ($matched == 0) {
    my @epoch_matches;
    while ($work =~ /[ \t]([0-9]{9,})[ \t]/g) {
      push @epoch_matches, { s => $-[1], e => $+[1], epoch => $1 };
    }

    if (@epoch_matches) {
      my $m = $epoch_matches[-1];
      my $prefix_text = substr($work, 0, $m->{s});
      my $tail = substr($work, $m->{e});
      $prefix_text =~ s/^[ \t]+//;
      $prefix_text =~ s/[ \t]+$//;

      my @toks = length($prefix_text) ? split(/\s+/, $prefix_text) : ();
      if (@toks >= 3) {
        my $perm_idx = 0;
        if ($toks[0] !~ $perms_re && $toks[0] =~ $blocks_re && @toks >= 2) {
          $perm_idx = 1;
        }
        if ($toks[$perm_idx] =~ $perms_re && defined $toks[$perm_idx + 1] && $toks[$perm_idx + 1] =~ /^\d+$/) {
          if ($has_human && $perm_idx == 1 && $toks[0] =~ /^([0-9]+)B$/) {
            $toks[0] = $1;
          }
          if ($has_human && $toks[-1] =~ /^\d+$/) { $toks[-1] = $toks[-1] . "B"; }
          my $rt = rel($m->{epoch});
          $_ = join(" ", @toks, $rt) . $tail . "\n";
        }
      }
    }
  }

  print $_;
}
