#!/usr/bin/perl -w
use strict;
use IO::File;
use List::Util qw(sum);

my $fh = IO::File->new("> lib/Barcode/PDF417/PP_Tables.pm");

print $fh <<EOS;
package Barcode::PDF417::PP_Tables;

use strict;
use warnings;
# Autogenerated, do not modify.

EOS

{
  my $iFh = IO::File->new("< data/codewords");
  my $eIdx = 0;
  print $fh "our \@codewords = (\n";
  while (<$iFh>) {
    s/(^\s*|\s$)//g;
    next unless $_;
    my ($idx,@cluster) = split(/\s/);
    die "sanity: $idx not expected index ($eIdx)\n" if $idx != $eIdx++;
    die "sanity: clusters != 3\n" if @cluster != 3;
    foreach my $x ( @cluster ) {
      die "sanity: invalid $idx $x\n" if $x !~ m/^[1-6]+$/ or sum( split(//,$x) ) != 17;
    }

    printf $fh "  ['%s','%s','%s'],  # %3i\n", @cluster, $idx;
  }
  die "sanity: invalid number of codewords\n" if $eIdx != 929;
  print $fh ");\n";
}

{
  my $iFh = IO::File->new("< data/coeff");
  my $inCoeff = 0;
  my @coeff;
  my $eIdx = 0;
  my $cIdx = -1;

  print $fh "our \@coeff = (\n";
  while (<$iFh>) {
    s/(^\s*|\s$)//g;
    next unless $_;
    if ( m/^(\d+):\s*(.*)\s*$/ ) {
      if ($inCoeff) {
        die "sanity: cIdx == -1\n" if $cIdx == -1;
        my $eCoeff = 2**($cIdx+1);
        die "sanity: got " . @coeff . ", expected $eCoeff coefficients for $cIdx\n" if $eCoeff != @coeff;
        print $fh "  [" . join(",",@coeff) . "], # $cIdx " . @coeff . "\n";
      }
      $cIdx = $1;
      my $data = $2;

      die "sanity: $cIdx not expected index ($eIdx)\n" if $cIdx != $eIdx++;
      @coeff = ();
      $inCoeff = 1;
      if ( $data ) {
        die "sanity: not numeric: '$data'\n" unless $data =~ m/^[\d\s]+$/;
        my @data = split(/\s+/,$data);
        @coeff = @data;
      }
    } elsif ( m/^[\d\s]+$/ ) {
      die "sanity: not in coefficient\n" unless $inCoeff;
      my @data = split(/\s+/,$_);
      push @coeff, @data;
    } else {
      die "Illegal line: $_\n";
    }
  }
  if ($inCoeff) {
    die "sanity: cIdx == -1\n" if $cIdx == -1;
    my $eCoeff = 2**($cIdx+1);
    die "sanity: got " . @coeff . ", expected $eCoeff coefficients for $cIdx\n" if $eCoeff != @coeff;
    print $fh "  [" . join(",",@coeff) . "], # $cIdx " . @coeff . "\n";
  }
  print $fh ");\n";
}

print $fh "\n\n1;\n";
