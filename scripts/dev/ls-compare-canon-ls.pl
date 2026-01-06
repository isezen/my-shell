use strict;
use warnings;

my $now = $ENV{LS_COMPARE_NOW_EPOCH};
$now = time() if !defined($now) || $now !~ /^-?\d+$/;
my $u = $ENV{LS_COMPARE_USER};
my $has_human  = $ENV{LS_COMPARE_HAS_HUMAN}  // 0;
my $prefix_w = 2;
my $num_w = 2;

sub fmt_rel {
  my ($prefix, $num, $unit) = @_;
  $unit = "hrs" if defined($unit) && $unit eq "hr";
  $unit = "mon" if defined($unit) && $unit eq "mo";
  return sprintf("%-*s %*d %s", $prefix_w, $prefix, $num_w, $num, $unit);
}

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

while (my $line = <STDIN>) {
  $_ = $line;

  if (defined($u) && length($u)) {
    s/(?<!\S)\Q$u\E(?!\S)/you/g;
  }

  s/[ \t]+$//;

  my $line = $_;
  chomp $line;
  $line =~ s/[ \t]+$//;

  # Parse by locating the final epoch span, then keep tail verbatim.
  my @epoch_matches;
  while ($line =~ /[\t ]([0-9]{9,})[\t ]/g) {
    push @epoch_matches, { s => $-[1], e => $+[1], epoch => $1 };
  }

  if (@epoch_matches) {
    my $m = $epoch_matches[-1];
    my $prefix = substr($line, 0, $m->{s});
    my $tail = substr($line, $m->{e});
    $prefix =~ s/^[ \t]+//;
    $prefix =~ s/[ \t]+$//;

    my @toks = length($prefix) ? split(/\s+/, $prefix) : ();
    if (@toks) {
      if ($has_human && $toks[-1] =~ /^\d+$/) { $toks[-1] = $toks[-1] . "B"; }
      my $rt = rel($m->{epoch});
      $_ = join(" ", @toks, $rt) . $tail . "\n";
    }
  }

  print $_;
}
