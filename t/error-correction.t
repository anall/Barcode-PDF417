#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;

plan tests => 1;

is_deeply( Barcode::PDF417::PP::_ec_codewords(1,[5,453,178,121,239]), [452,327,657,619], "sample Annex Q" );

