#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Exception;
use List::Util qw(sum);

use Barcode::PDF417::PP;

# Note; duplicated from Barcode::PDF417::PP
my $tc_al = 0xFA;
my $tc_as = 0xFB;
my $tc_ll = 0xFC;
my $tc_ml = 0xFD;
my $tc_pl = 0xFE;
my $tc_ps = 0xFF;

sub test_preprocess {
  my ($expl,$inStr,$expOut,%opts) = @_;
  lives_and {
    subtest "$expl-inner" => sub {
      plan tests => 1 + (exists $opts{overhead} ? 1 : 0);
      my $result;
      is_deeply(
        $result = Barcode::PDF417::PP::_preprocess_text($inStr,
          ($opts{fast} ? 1 : 0) ), $expOut, "preprocess" );
      if ( exists $opts{overhead} ) {
        my $characters = sum(map { 1+length($_->[1]) } @$result);
        is($characters,$opts{overhead}+length($inStr),"overhead");
      }
    }
  }, $expl;
}

subtest "preprocess", sub {
  plan tests => 20;
  
  test_preprocess('AlphaRegex', 'HELLO WORLD', [ ['al','HELLO WORLD'] ], overhead => 1);
  test_preprocess('LowerRegex', 'hello world', [ ['ll','hello world'] ], overhead => 1);
  test_preprocess('MixedRegex', '1024', [ ['ml','1024'] ], overhead => 1);
  test_preprocess('PunctRegex', '()', [ ['ps','('], ['ps',')'] ], overhead => 2);

  test_preprocess('PunctRegex - Under solo', '(()a', [['ps','('],['ps','('],['ps',')'],['ll','a']], overhead => 4);
  test_preprocess('PunctRegex - Latch solo', '(())a',
    [ ['pl','(())'],['ll','a'] ], overhead=>2); # really 4 -- outer overhead to actually reach this mode not included.
  test_preprocess('PunctRegex - Fast solo', '(())a',
    [['ps','('],['ps','('],['ps',')'],['ps',')'],['ll','a']], overhead=>5, fast=>1);

  test_preprocess('PunctRegex - Under to_al', '((A', [['ps','('],['ps','('],['al','A']], overhead => 3);
  test_preprocess('PunctRegex - Latch to_al', '(()A',
    [ ['pl','(()'], ['al','A']], overhead=>2); # really 3 -- outer overhead to actually reach this mode not included.
  test_preprocess('PunctRegex - Fast to_al', '(()A',
    [['ps','('],['ps','('],['ps',')'],['al','A']], overhead=>4, fast=>1); # really 3 -- extra overhead

  test_preprocess('PunctRegex - Under ml_al', '9(A', [['ml','9'],['ps','('],['al','A']], overhead => 3);
  test_preprocess('PunctRegex - Latch ml_al', '9()A',
    [['ml','9'],['pl','()'],['al','A']], overhead => 3); # figure is correct here.
  test_preprocess('PunctRegex - Fast ml_al', '9()A',
    [['ml','9'],['ps','('],['ps',')'],['al','A']], overhead => 4, fast => 1); # figure is correct here.

  test_preprocess('PunctRegex - Under ml_?', '9((a', [['ml','9'],['ps','('],['ps','('],['ll','a']], overhead => 4);
  test_preprocess('PunctRegex - Latch ml_?', '9(()a',
    [['ml','9'],['pl','(()'],['ll','a']], overhead => 3); # really 4 -- outer overhead to actually reach this mode not included.
  test_preprocess('PunctRegex - Fast ml_?', '9(()a',
    [['ml','9'],['ps','('],['ps','('],['ps',')'],['ll','a']], overhead => 5, fast => 1); # figure is correct here.
  
  test_preprocess('Mixed Case', 'Hello World', [ ['al','H'], ['ll','ello '], ['as','W'], ['ll','orld'] ], overhead => 4); # really 3
  test_preprocess('Mixed Case 2', 'Hello WWorld', [ ['al','H'], ['ll','ello '], ['as','W'],['as','W'],['ll','orld'] ], overhead => 5);
  test_preprocess('Mixed Case 3', 'Hello WWWorld', [ ['al','H'], ['ll','ello '], ['as','W'],['as','W'],['as','W'],['ll','orld'] ], overhead => 6);
  test_preprocess('Mixed Case 4', 'Hello WWWWorld', [ ['al','H'], ['ll','ello '], ['al','WWWW'],['ll','orld'] ], overhead => 4);
};

subtest "preencode", sub {
    my $al = chr(0xFA);
    my $as = chr(0xFB);
    my $ll = chr(0xFC);
    my $ml = chr(0xFD);
    my $pl = chr(0xFE);
    my $ps = chr(0xFF);

    my $pre_and_fmt = sub {
        my $x = Barcode::PDF417::PP::_preencode_text($_[0]);
        $x =~ s/$al/<al>/g;
        $x =~ s/$as/<as>/g;
        $x =~ s/$ll/<ll>/g;
        $x =~ s/$ml/<ml>/g;
        $x =~ s/$pl/<pl>/g;
        $x =~ s/$ps/<ps>/g;
        return $x;
    };

    is($pre_and_fmt->("Hello World"), "H<ll>ello <as>World");
    is($pre_and_fmt->("I have \$200,000?"), "I <ll>have <ml>\$200,000<ps>?");
    is($pre_and_fmt->("I have \$200,000?!?"), "I <ll>have <ml>\$200,000<pl>?!?");
    is($pre_and_fmt->("xOMg"), "<ll>x<as>O<as>Mg");
    is($pre_and_fmt->("xOMG"), "<ll>x<ps><al>OMG");
    is($pre_and_fmt->("1OM"), "<ml>1<al>OM");
    is($pre_and_fmt->("???OM"), "<ml><pl>???<al>OM");
    is($pre_and_fmt->("????om"), "<ml><pl>????<al><ll>om");
    is($pre_and_fmt->("PDF417"), "PDF<ml>417");

    done_testing();
};

subtest "preencode", sub {
    is_deeply( scalar(Barcode::PDF417::PP::_compact_text("PDF417",0)),[453,178,121,239], "PDF417 -- from manual");

    done_testing();
};

done_testing();
