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
    push @codewords, @{_compact_number_raw($tIn)};
  }
  return [902,@codewords];
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

sub _measure_symbol($$$$) {
  my ($r,$c,$ec,$m) = @_;
  die "sanity: r $r out of bounds\n" if $r < 3 || $r > 90;
  die "sanity: c $c out of bounds\n" if $c < 1 || $c > 30;

  my $n = $c*$r - 2**($ec+1);
  die "cannot fit EC\n" if $n < 0;

  my $pad = $n-$m-1;
  die "cannot fit code\n" if $pad < 0;

  return ($n,$pad);
}

sub _pad_codewords($$$) {
  my ($codewords, $n, $pads) = @_;
  return [ $n, @$codewords, ( map { 900 } (1..$pads) ) ];
}

sub _final_codewords($$$$) {
  my ($codewords,$r,$c,$ec) = @_;

  my ($n,$pads) = _measure_symbol($r,$c,$ec,$#$codewords + 1);
  $codewords = _pad_codewords($codewords,$n,$pads);
  my $ecWords = _ec_codewords($codewords,$ec);

  my @toPlace = ( @$codewords,@$ecWords );
  return \@toPlace;
}

sub _build_symbol($$$$) {
  my ($codewords,$nR,$nC,$ec) = @_;
  my $toPlace = _final_codewords($codewords,$nR,$nC,$ec);
  my @outData;
  my $idx = 0;
  for ( my $r = 0; $r < $nR; ++$r ) {
    my ($lr,$rr) = _row_codewords($r,$nR,$nC,$ec);
    my $k = $r % 3;

    my $rowData = $startSymbol . $Barcode::PDF417::PP_Tables::codewords[$lr][$k];
    for (my $c = 0; $c < $nC; ++$c ) {
      $rowData .= $Barcode::PDF417::PP_Tables::codewords[$toPlace->[$idx++]][$k];
    }
    push @outData, $rowData . $Barcode::PDF417::PP_Tables::codewords[$rr][$k] . $endSymbol;
  }
  return \@outData;
}

1;
