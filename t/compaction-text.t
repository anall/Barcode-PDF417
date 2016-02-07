#!/usr/bin/perl -w
use strict;
use List::Util qw(sum);

use Test::More tests => 4;
use Test::Exception;

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

subtest "preprocess, no overhead", sub {
  plan tests => 2;
  is_deeply( Barcode::PDF417::PP::_preprocess_text("111,,,]"),[ ['ml','111,,,'], ['ps',']'] ]);
  is_deeply( Barcode::PDF417::PP::_preprocess_text("!!!!11"), [ ['pl','!!!!'], ['ml','11'] ]);
};

subtest "preencode", sub {
    plan tests => 16;

    my $c_al = chr($tc_al);
    my $c_as = chr($tc_as);
    my $c_ll = chr($tc_ll);
    my $c_ml = chr($tc_ml);
    my $c_pl = chr($tc_pl);
    my $c_ps = chr($tc_ps);

    my $pre_and_fmt = sub {
        my $x = Barcode::PDF417::PP::_preencode_text($_[0],$_[1],$_[2]);
        $x =~ s/$c_al/<al>/g;
        $x =~ s/$c_as/<as>/g;
        $x =~ s/$c_ll/<ll>/g;
        $x =~ s/$c_ml/<ml>/g;
        $x =~ s/$c_pl/<pl>/g;
        $x =~ s/$c_ps/<ps>/g;
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

    # Let's try pre-existing
    is($pre_and_fmt->("PDF417",undef,$tc_ml), "<al>PDF<ml>417");
    is($pre_and_fmt->("PDF417",undef,$tc_ll), "<ps><al>PDF<ml>417");

    is($pre_and_fmt->("PDF417!!!"), "PDF<ml>417<pl>!!!");
    is($pre_and_fmt->("PDF417!"), "PDF<ml>417<ps>!");

    is($pre_and_fmt->("!!!!aa"), "<ml><pl>!!!!<al><ll>aa");
    is($pre_and_fmt->("!!!!AA"), "<ml><pl>!!!!<al>AA");
    is($pre_and_fmt->("!!!!11"), "<ml><pl>!!!!<al><ml>11");
};

subtest "preencode", sub {
    plan tests => 4;

    is_deeply( scalar(Barcode::PDF417::PP::_compact_text("PDF417",0)),[453,178,121,239], "PDF417 -- from manual");
    is_deeply( scalar(Barcode::PDF417::PP::_compact_text("PDF41",0)),[453,178,121], "PDF41");
    is_deeply( scalar(Barcode::PDF417::PP::_compact_text("PDF417!!!",0)),[453,178,121,235,310,329],"PDF<ml>417<pl>!!!");
    is_deeply( scalar(Barcode::PDF417::PP::_compact_text("PDF417!",0)),[453,178,121,239,329],"PDF<ml>417<pl>!!!");
};
