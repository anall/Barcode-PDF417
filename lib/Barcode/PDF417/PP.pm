package Barcode::PDF417::PP;
use Barcode::PDF417::PP_Tables;
use Data::Dump qw(dump);

use strict;
use warnings;

my $startSymbol = "81111113";
my $endSymbol   = "711311121";

sub _compact_number($) {
  my ($t) = $_[0];
  die "sanity: '$t' is not numeric" unless $t =~ m/^\d+$/;
  return () unless length($t);

  my @codewords;
  while ( length($t) ) {
    my $tIn = substr($t,0,44);
    $t = length($t) > 44 ? substr($t,44) : ""; 
    push @codewords, 902, @{_compact_number_raw($tIn)};
  }
  return \@codewords;
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
    unshift @codewords, $t % 900;
    $t = int( $t/900 );
  }
  return \@codewords;
}

# FIXME: Reverse this algorithm so the final reverse of @E is not needed
sub _ec_codewords($$) {
  my ($level,$codewords) = @_;
  my $n = @$codewords;
  my $k = 2**($level+1);
  die "sanity: length not correct\n" if $n != $codewords->[0];
  my $A = $Barcode::PDF417::PP_Tables::coeff[$level] or die "sanity: invalid level $level\n";
  my @E = map { 0 } 1 .. $k;

  my ($t1,$t2,$t3);
  for ( my $i = 0; $i < @$codewords; ++$i ) {
    $t1 = ( $codewords->[$i] + $E[-1] ) % 929;
    for ( my $j = $k-1; $j >= 0; --$j ) {
      $t2 = ($t1 * $A->[$j]) % 929;
      $t3 = 929 - $t2;
      $E[$j] = ( ( $j > 0 ? $E[$j-1] : 0 ) + $t3 ) % 929;
    }
  }
  return [ map { 929 - $_ } reverse @E ];
}

1;
