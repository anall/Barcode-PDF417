#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Barcode::PDF417' ) || print "Bail out!\n";
}

diag( "Testing Barcode::PDF417 $Barcode::PDF417::VERSION, Perl $], $^X" );
