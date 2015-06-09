#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;
plan tests => 1;

subtest "preprocess", sub {
  plan tests => 15;
  
  is( Barcode::PDF417::PP::_preprocess_text("\xFF"), undef, "invalid start" );
  is( Barcode::PDF417::PP::_preprocess_text("Hello\xFFWorld"), undef, "invalid middle" );
  is( Barcode::PDF417::PP::_preprocess_text("Hello\xFF"), undef, "invalid end" );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('hello world'),
    [ ['ll','hello world'] ], '"hello world"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('Hello World'),
    [ ['al','H'], ['ll','ello '], ['al','W'], ['ll','orld'] ], '"Hello World"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('Hello World$$$$'),
    [ ['al','H'], ['ll','ello '], ['al','W'], ['ll','orld'], ['ml','$$$$'] ], '"Hello World$$$$"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text(':!:'),
    [ ['pl',':!:'] ], '":!:"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('!:!'),
    [ ['pl','!:!'] ], '"!:!"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('!:!A'),
    [ ['pl','!:!'], ['al','A'] ], '"!:!A"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('!:!:a'),
    [ ['pl','!:!:'], ['ll','a' ] ], '"!:!:a"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('a!:!:a'),
    [ ['ll','a'], ['pl','!:!:'], ['ll','a' ] ], '"a!:!:a"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('200:!:'),
    [ ['ml','200:'], ['pl','!:'] ], '"200:!:"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('200:!:!a'),
    [ ['ml','200:'], ['pl','!:!'], ['ll','a'] ], '"200:!:!a"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('200:!:A'),
    [ ['ml','200:'], ['pl','!:'], ['al','A'] ], '"200:!:A"' );
  
  is_deeply( Barcode::PDF417::PP::_preprocess_text('200:!:',1),
    [ ['ml','200:'], ['ps','!'], ['ml',':'] ], '"200:!:" fast' );
}
