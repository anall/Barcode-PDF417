#!/usr/bin/perl -w
use strict;
use List::Util qw(sum);
use File::Temp qw( tempdir );
use IO::File;

use Test::More;
use Test::Exception;

use Barcode::PDF417::PP;

# Note, this test is mostly for development use, but may be useful to run if you are having problems.
# I am using an existing project v.s. writing my own decoder to try and rule out a bug.
#  If there is a bug in my encoding, there will likely be a bug in my *decoder*.

# To use:
#   Grab the latest core and javase JARs following the instructions at https://github.com/zxing/zxing/wiki/Getting-Started-Developing
#    and put them in the 'java' directory.
#
#   Compile BarcodePDF417Decode.java with: javac -cp core.jar:javase.jar BarcodePDF417Decode.java

plan( skip_all => "decode tests are disabled" ) if $ENV{NO_DECODE_TEST};
plan( skip_all => "ZXing missing, not running decode tests -- see t/decode-simple.t for info" ) unless -e 'java/core.jar' and -e 'java/javase.jar';
plan( skip_all => "Java helper missing, not running decode tests -- see t/decode-simple.t for info" ) unless -e 'java/lib/BarcodePDF417Decode.class';


my $dir = tempdir( CLEANUP => $ENV{TEST_KEEP_FILES} ? 0 : 1 );
my $fileId = 0;
diag("dir is: $dir") if $ENV{TEST_KEEP_FILES};

sub mangle($$$) {
  my ($d,$r,$c) = @_;
  my @tmp = split(//,$d->[$r]);
  my $tmp = $tmp[$c];
  $tmp[$c] = $tmp[$c+1];
  $tmp[$c+1] = $tmp;
  $d->[$r] = join('',@tmp);
}

sub confirm($$;$) {
  my ($d,$expected,$descr) = @_;
  my $wide = sum( split(//,$d->[0]) );
  my $sidePadding = 10;
  my $charMul = 5;
  my $lineMul = $charMul * 3;

  my $tall = @$d;
  my $data = ( ("\xFF" x ($wide*$charMul+$sidePadding*2)) ) x $sidePadding;
  foreach my $iData ( @$d ) {
    my $val = 0;
    my $line = "";
    foreach my $n ( split(//,$iData) ) {
      $val = ($val+1)&1;
      $line .= ($val ? "\0" : "\xFF") x ($n*$charMul);
    }
    $data .= ("\xFF" x $sidePadding) . $line . ("\xFF" x $sidePadding) foreach (1 .. $lineMul);
  }
  $data .= ( ("\xFF" x ($wide*$charMul+$sidePadding*2)) ) x $sidePadding;

  {
    my $fh = IO::File->new("> $dir/tmp.pgm");
    print $fh "P5\n" . ($wide*$charMul+$sidePadding*2) . " " . ($tall*$lineMul+$sidePadding*2) . "\n255\n$data";
  }

  system("pnmtopng $dir/tmp.pgm > $dir/" . (++$fileId) . ".png 2>/dev/null");

  my $result = `java -cp java/lib:java/core.jar:java/javase.jar BarcodePDF417Decode $dir/$fileId.png`;
  my ($type,$ecLevel,$codewords,$oData) = split(/\n/,$result);

  my $bin = pack("H*",$oData);
  $descr ||= "code: $expected";

  subtest $descr => sub {
    plan tests => 2;
    is( $type, "PDF_417", "type");
    is( $bin, $expected, "data");
  }
}

plan tests => 7;

{
  my $n = 20 * 900**5 + 32 * 900**4 + 48 * 900**3 + 900**2 + 900**1;
  my $parts = Barcode::PDF417::PP::_compact_number($n);

  confirm(Barcode::PDF417::PP::_build_symbol($parts,6,2,1),$n, "ec 1 $n");
  confirm(Barcode::PDF417::PP::_build_symbol($parts,4,6,3),$n, "ec 1 $n");
}

{
  my $n = "123456789" x 8;
  my $parts = Barcode::PDF417::PP::_compact_number($n);
  confirm(Barcode::PDF417::PP::_build_symbol($parts,16,18,7),$n, "ec 1 $n");
  confirm(Barcode::PDF417::PP::_build_symbol($parts,32,9,7),$n, "ec 1 $n");
}

{
  my $partsA = Barcode::PDF417::PP::_compact_number("1234");
  my $partsB = Barcode::PDF417::PP::_compact_number("9876");
  confirm(Barcode::PDF417::PP::_build_symbol([@$partsA, @$partsB],10,10,5),"12349876", "two number pairs");
}

confirm(Barcode::PDF417::PP::_build_symbol(Barcode::PDF417::PP::_compact_text("PDF417"),10,10,5),"PDF417", "PDF417 w/ latch");
confirm(Barcode::PDF417::PP::_build_symbol(Barcode::PDF417::PP::_compact_text("PDF417",0),10,10,5),"PDF417", "PDF417 w/o latch");
