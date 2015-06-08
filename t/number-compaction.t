#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;

plan tests => 6;

throws_ok { Barcode::PDF417::PP::_compact_number_raw("-1") } qr/is not numeric/, "negative numbers";
throws_ok { Barcode::PDF417::PP::_compact_number_raw("Pi is 3.14") } qr/is not numeric/, "text";
throws_ok { Barcode::PDF417::PP::_compact_number_raw("0" x 45) } qr/trying to compact/, "too long";
is_deeply(  Barcode::PDF417::PP::_compact_number_raw("00"), [100], "compact 00" );

# Example sequence from ISO/IEC 15438:2006
is_deeply( Barcode::PDF417::PP::_compact_number_raw("000213298174000"), [1,624,434,632,282,200], "compact raw 000213298174000" );

is_deeply( Barcode::PDF417::PP::_compact_number("000213298174000"), [902,1,624,434,632,282,200], "compact 000213298174000" );

# FIXME: Add test for multi-block _compact_number
