#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;

plan tests => 1;

#throws_ok { Barcode::PDF417::PP::_compact_number_raw("-1") } qr/is not numeric/, "negative numbers raw";
#throws_ok { Barcode::PDF417::PP::_compact_number_raw("Pi is 3.14") } qr/is not numeric/, "text raw";
#throws_ok { Barcode::PDF417::PP::_compact_number_raw("0" x 45) } qr/trying to compact/, "too long raw";

# Example sequence from ISO/IEC 15438:2006
is_deeply(  Barcode::PDF417::PP::_compact_byte_raw(pack("C*",231,101,11,97,205,2)), [387,700,208,213,302], "{231,101,11,197,205,2}" );

