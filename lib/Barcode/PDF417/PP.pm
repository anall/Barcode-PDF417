package Barcode::PDF417::PP;

use strict;
use warnings;

sub _compact_number($) {
  my ($t) = $_[0];
  die "sanity: '$t' is not numeric" unless $t =~ m/^\d+$/;
  return () unless length($t);

  my @codewords;
  while ( length($t) ) {
    my $tIn = substr($t,0,44);
    $t = length($t) > 44 ? substr($t,44) : ""; 
    push @codewords, 902, _compact_number_raw($tIn);
  }
  return @codewords;
}

sub _compact_number_raw($) {
  my ($t) = $_[0];
  die "sanity: '$t' is not numeric" unless $t =~ m/^\d+$/;
  die "sanity: trying to compact '$t', which is '" . length($t) . "' digits long. Expected <=44"
    unless length($t) <= 44;
  $t = "1$t";

  my @codewords;
  while ($t != 0) { 
    die "sanity: $t is negative" if $t < 0;
    push @codewords, $t % 900;
    $t = int( $t/900 );
  }
  return @codewords;
}

1;
