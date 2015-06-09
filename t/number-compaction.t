#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;

plan tests => 9;

throws_ok { Barcode::PDF417::PP::_compact_number_raw("-1") } qr/is not numeric/, "negative numbers raw";
throws_ok { Barcode::PDF417::PP::_compact_number_raw("Pi is 3.14") } qr/is not numeric/, "text raw";
throws_ok { Barcode::PDF417::PP::_compact_number_raw("0" x 45) } qr/trying to compact/, "too long raw";
is_deeply(  Barcode::PDF417::PP::_compact_number_raw("00"), [100], "compact 00 raw" );

throws_ok { Barcode::PDF417::PP::_compact_number("Pi is 3.14") } qr/is not numeric/, "text";

# Example sequence from ISO/IEC 15438:2006
is_deeply( Barcode::PDF417::PP::_compact_number_raw("000213298174000"), [1,624,434,632,282,200], "compact raw 000213298174000" );

is_deeply( Barcode::PDF417::PP::_compact_number("000213298174000"), [902,1,624,434,632,282,200], "compact 000213298174000" );

is_deeply( Barcode::PDF417::PP::_compact_number("83217915100911234705228031145717463848720800"),
  [ 902, map { 800 } (0..14) ], "large number, one block");

is_deeply( Barcode::PDF417::PP::_compact_number("832179151009112347052280311457174638487208001"),
  [ 902, (map { 800 } (0..14)), 11 ], "large number, two blocks");
