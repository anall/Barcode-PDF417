#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;

plan tests => 1;

my @data = ( 902, ( map { 0 } (1..244) ), 423 );
my ($n,$pads) =  Barcode::PDF417::PP::_measure_symbol(24,12,4,$#data+1);
is_deeply(
  Barcode::PDF417::PP::_pad_codewords(\@data, $n ,$pads ),
  [256,@data,(map { 900 } (1..9))], "sample from docs" );

