#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;

plan tests => 5;

throws_ok { Barcode::PDF417::PP::_ec_codewords([],1) } qr/empty/, "empty";
throws_ok { Barcode::PDF417::PP::_ec_codewords([3,1],1) } qr/length not correct/, "invalid lenght";
throws_ok { Barcode::PDF417::PP::_ec_codewords([2,1],9) } qr/invalid level/, "invalid level (positive)";
throws_ok { Barcode::PDF417::PP::_ec_codewords([2,1],-1) } qr/invalid level/, "invalid level (negative)";

is_deeply( Barcode::PDF417::PP::_ec_codewords([5,453,178,121,239],1), [452,327,657,619], "sample Annex Q" );

