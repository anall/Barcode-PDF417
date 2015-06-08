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
    unshift @codewords, $t % 900;
    $t = int( $t/900 );
  }
  return \@codewords;
}

# FIXME: Reverse this algorithm so the final reverse of @E is not needed
sub _ec_codewords($$) {
  my ($codewords,$level) = @_;
  my $n = @$codewords;
  my $k = 2**($level+1);
  die "sanity: input string is empty\n" if $n == 0;
  die "sanity: length not correct\n" if $n != $codewords->[0];
  die "sanity: invalid level $level\n" if $level < 0 || $level > 8;
  my $A = $Barcode::PDF417::PP_Tables::coeff[$level];
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
  return [ map { $_ == 0 ? 0 : 929 - $_ } reverse @E ];
}

sub _row_codewords($$$$) {
  my ($F,$r,$c,$s) = @_;
  my $k = $F % 3;
  die "sanity: $k out of range\n" if $k < 0 || $k > 2;
  my $lr = 30 * int( ($F-1)/3 ) + (
    $k == 0 ? int( ($r - 1)/3 ) :
    $k == 1 ? ( $s * 3 + ($r-1)%3 ) :
              ( $c - 1 ) );
  my $rr = 30 * int( ($F-1)/3 ) + (
    $k == 0 ? ($c - 1) :
    $k == 1 ? int( ($r-1)/3 ) :
              ( ($s * 3) + ($r-1) % 3 ) );
#  die "sanity: $lr out of range\n" if $lr < 0;
#  die "sanity: $rr out of range\n" if $rr < 0;
  return ($lr,$rr);
}

sub _build_symbol($$$$) {
  my ($codewords,$nR,$nC,$ec) = @_;
  die "sanity: r $nR out of bounds\n" if $nR < 3 || $nR > 90;
  die "sanity: c $nC out of bounds\n" if $nC < 1 || $nC > 30;
  die "sanity: length not correct\n" if @$codewords != $codewords->[0];
  
  my $spaceNeeded = $codewords->[0] + 2**($ec+1);
  die "sanity: insufficient space $spaceNeeded " . ($nR*$nC) . "\n" if $nR*$nC < $spaceNeeded;

  die "NOT IMPLEMENTED PADDING\n" if $nR*$nC > $spaceNeeded;

  my $ecWords = _ec_codewords($codewords,$ec);

  die "sanity: invalid codeword(s) in codewords\n" if grep { $_ < 0 || $_ >= 929 } @$codewords;
  die "sanity: invalid codeword(s) in error correction\n" if grep { $_ < 0 || $_ >= 929 } @$ecWords;

  my @toPlace = (@$codewords,@$ecWords);
  my @outData;
  my $idx = 0;
  for ( my $r = 0; $r < $nR; ++$r ) {
    my ($lr,$rr) = _row_codewords($r,$nR,$nC,$ec);
    my $k = $r % 3;

    my $rowData = $startSymbol . $Barcode::PDF417::PP_Tables::codewords[$lr][$k];
    for (my $c = 0; $c < $nC; ++$c ) {
      die "sanity: $idx out of range\n" if $idx >= @toPlace;
      $rowData .= $Barcode::PDF417::PP_Tables::codewords[$toPlace[$idx++]][$k];
    }
    push @outData, $rowData . $Barcode::PDF417::PP_Tables::codewords[$rr][$k] . $endSymbol;
  }

  return \@outData;
}

1;
