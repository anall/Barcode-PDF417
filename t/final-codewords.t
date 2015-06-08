#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;

use Barcode::PDF417::PP;

plan tests => 1;

is_deeply( Barcode::PDF417::PP::_final_codewords([902,189,347,759,224,412,100],6,2,1), [8,902,189,347,759,224,412,100,190,795,635,269] );

