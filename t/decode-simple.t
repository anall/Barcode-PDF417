#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use List::Util qw(sum);
use File::Temp qw( tempdir );

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
plan( skip_all => "Java helper, not running decode tests -- see t/decode-simple.t for info" ) unless -e 'java/BarcodePDF417Decode.class';

eval "use Image::Magick;";
plan( skip_all => "Image::Magick missing, not running decode tests" ) if $@;

plan tests => 1;

my $dir = tempdir( CLEANUP => 0 );
print "$dir\n";

sub confirm($$;$) {
  my ($d,$expected,$descr) = @_;
  my $wide = sum( split(//,$d->[0]) );
  my $tall = @$d;
  my $data = ( ("\xFF" x ($wide*2+10)) ) x 5;
  foreach my $iData ( @$d ) {
    my $val = 0;
    my $line = "";
    foreach my $n ( split(//,$iData) ) {
      $val = ($val+1)&1;
      $line .= ($val ? "\0\0" : "\xFF\xFF") x $n;
    }
    $data .= "\xFF\xFF\xFF\xFF\xFF$line\xFF\xFF\xFF\xFF\xFF";
    $data .= "\xFF\xFF\xFF\xFF\xFF$line\xFF\xFF\xFF\xFF\xFF";
    $data .= "\xFF\xFF\xFF\xFF\xFF$line\xFF\xFF\xFF\xFF\xFF";
    $data .= "\xFF\xFF\xFF\xFF\xFF$line\xFF\xFF\xFF\xFF\xFF";
    $data .= "\xFF\xFF\xFF\xFF\xFF$line\xFF\xFF\xFF\xFF\xFF";
    $data .= "\xFF\xFF\xFF\xFF\xFF$line\xFF\xFF\xFF\xFF\xFF";
  }
  $data .= ( ("\xFF" x ($wide*2+10)) ) x 5;

  {
    my $fh = IO::File->new("> $dir/tmp.pgm");
    print $fh "P5\n" . ($wide*2+10) . " " . ($tall*6+10) . "\n255\n$data";
  }

  {
    my $p = Image::Magick->new;
    $p->Read("$dir/tmp.pgm");
    $p->Write("$dir/tmp.png");
  }

  my $result = `java -cp java:java/core.jar:java/javase.jar BarcodePDF417Decode $dir/tmp.png`;
  my ($type,@data) = split(/\n/,$result);

  my $bin;
  foreach my $line (@data) {
    $bin .= join('',map { chr($_ ) } split(/\s/,$line));
  }
  $descr ||= "code: $expected";

  subtest $descr => sub {
    plan tests => 2;
    is( $type, "PDF_417", "type");
    is( $bin, $expected, "data");
  }
}

my $n = 900**5 + 900**4 + 900**3 + 900**2 + 900**1;
my $parts = Barcode::PDF417::PP::_compact_number($n);
my @out = ( scalar(@$parts)+1,@$parts );
my $data;

print Dumper($parts);

subtest "1024 all ec" => sub {
  plan tests => 7;
  # can't test 0, without padding
  confirm(Barcode::PDF417::PP::_build_symbol(\@out,4+  2,2,1),$n, "ec 1 $n");
  confirm(Barcode::PDF417::PP::_build_symbol(\@out,4+  4,2,2),$n, "ec 2 $n");
  confirm(Barcode::PDF417::PP::_build_symbol(\@out,4+  8,2,3),$n, "ec 3 $n");
  confirm(Barcode::PDF417::PP::_build_symbol(\@out,4+ 16,2,4),$n, "ec 4 $n");
  confirm(Barcode::PDF417::PP::_build_symbol(\@out,4+ 32,2,5),$n, "ec 5 $n");
  confirm(Barcode::PDF417::PP::_build_symbol(\@out,4+ 64,2,6),$n, "ec 6 $n");
  confirm(Barcode::PDF417::PP::_build_symbol(\@out,2+ 64,4,7),$n, "ec 7 $n");
# confirm(Barcode::PDF417::PP::_build_symbol(\@out,1+ 64,8,8),$n, "ec 8 $n");
}
