package Barcode::PDF417::PP;
use Barcode::PDF417::PP_Tables;

use strict;
use warnings;

my $startSymbol = "81111113";
my $endSymbol   = "711311121";

my %tc_modes = (
  al => 0xFA,
  as => 0xFB,
  ll => 0xFC,
  ml => 0xFD,
  pl => 0xFE,
  ps => 0xFF
);

my @tc_Alpha = ( map { chr($_) } ( ( 65 ..  90), 32,
  $tc_modes{ll}, $tc_modes{ml}, $tc_modes{ps} ) );
my @tc_Lower = ( map { chr($_) } ( ( 97 .. 122), 32,
  $tc_modes{as}, $tc_modes{ml}, $tc_modes{ps} ) );
my @tc_Mixed = ( map { chr($_) } ( (48..57),
   38,  13,   9,  44,  58,  35,  45,  46,  36,  47,  43,  37,  42,  61,  94,
   $tc_modes{pl}, 32, $tc_modes{ll}, $tc_modes{al}, $tc_modes{ps} ) );
my @tc_Punct = ( map { chr($_) } (
   59,  60,  62,  64,  91,  92,  93,  95,  96, 126,  33,  13,   9,  44,  58,
   10,  45,  46,  36,  47,  34, 124,  42,  40,  41,  63, 123, 125,  39,
   $tc_modes{al} ) );

my %tc_Alpha = ( map { $tc_Alpha[$_] => $_ } ( 0 .. $#tc_Alpha ) );
my %tc_Lower = ( map { $tc_Lower[$_] => $_ } ( 0 .. $#tc_Lower ) );
my %tc_Mixed = ( map { $tc_Mixed[$_] => $_ } ( 0 .. $#tc_Mixed ) );
my %tc_Punct = ( map { $tc_Punct[$_] => $_ } ( 0 .. $#tc_Punct ) );

my %tc_ModePoint = (
  $tc_modes{al} => \%tc_Alpha,
  $tc_modes{as} => \%tc_Alpha,
  $tc_modes{ll} => \%tc_Lower,
  $tc_modes{ml} => \%tc_Mixed,
  $tc_modes{pl} => \%tc_Punct,
  $tc_modes{ps} => \%tc_Punct,
);

my $tc_AlphaRegex = quotemeta join("",grep { ord($_) < 0xF0 } @tc_Alpha);
my $tc_LowerRegex = quotemeta join("",grep { ord($_) < 0xF0 } @tc_Lower);
my $tc_MixedRegex = quotemeta join("",grep { ord($_) < 0xF0 } @tc_Mixed);
my $tc_PunctRegex = quotemeta join("",grep { ord($_) < 0xF0 } @tc_Punct);
my $tc_ModeSwitch = quotemeta join("",grep { ord($_) > 0xF0 } map { chr($_) } values %tc_modes);

my $tc_RegexFast = qr/\G(?:
  (?<al>[$tc_AlphaRegex]+)|
  (?<ll>[$tc_LowerRegex]+)|
  (?<ml>[$tc_MixedRegex]+)|
  (?<ps>[$tc_PunctRegex])
)/x;

my $tc_Regex = qr/\G(?:
#  (?<as>(?<=[$tc_LowerRegex])[$tc_AlphaRegex](?=[^$tc_AlphaRegex]))| # To encode 1 characters it's <as>X<?l>  (3) v.s. <?l><al>X<?l> (4)
  (?<as>(?<=[$tc_LowerRegex])[$tc_AlphaRegex]{1,3}(?=[$tc_LowerRegex]))| # To encode 3 characters it's <as>X<as>X<as>X (6) v.s. <ml><al>XXX<ll> (6)
  (?<al>[$tc_AlphaRegex]+)|
  (?<ll>[$tc_LowerRegex]+)|
  (?<pl>(?<=[$tc_MixedRegex])[$tc_PunctRegex]{2,}(?=[$tc_AlphaRegex]|$))| # This is pretty much free for 1, as we just need <pl> but require 2 to prevent useless switching.
  (?<pl>(?<=[$tc_MixedRegex])[$tc_PunctRegex]{3,})| # We need <pl>...<al><return> -- 3 characters take up 6 for this, v.s. 6 for <ps>.
  (?<ml>[$tc_MixedRegex]+)|
  (?<pl>[$tc_PunctRegex]{3,}(?=[$tc_AlphaRegex]|$))| # We need <ml><pl>...<al> -- 3 characters takes up 6 v.s. 6 for <ps>.
  (?<pl>[$tc_PunctRegex]{4,})| # We need <ml><pl>...<al><return> -- 3 characters takes up 7 v.s. 8 for <ps>
  (?<ps>[$tc_PunctRegex])
)/x;

sub _preprocess_text($;$) {
  my ($t,$fast) = @_;
  my @out;
  my $regex = $fast ? $tc_RegexFast : $tc_Regex;
  while ( $t =~ m/$regex/gc ) {
    #die "sanity: got wrong number of matches\n" if keys %+ != 1;
    my ($mode,$data) = %+; # I know this is horrible.
    if ( $mode eq 'pl' and @out and $out[-1][0] =~ m/ps|ml/ and $out[-1][1] =~ m/^[$tc_PunctRegex]$/ ) {
      # If our previous is ml or ps, and can be encoded with PunctRegex, and we are going into pl -- switch the current one to pl
      #  The cost is the same.
      $out[-1][0] = $mode;
      $out[-1][1] .= $data;
    } elsif ( $mode =~ m/^.s$/ ) {
      push @out, [$mode,$_] foreach split(//,$data); # I know this is horrible.
    } else {
      push @out, [$mode,$data]; # I know this is horrible.
    }
  }
  die "got unknown character at " . (pos($t)||0) if (pos($t)||0) ne length($t);
  return \@out;
}

# FIXME: make curMode respect 
sub _preencode_text($;$$) {
  my ($t,$fast,$curMode) = @_;

  $curMode //= $tc_modes{al};
  my $plan = _preprocess_text($t,$fast // 0);

  my $out;
  foreach my $item ( @$plan ) {
    my $newMode = $tc_modes{$item->[0]};
    if ( $curMode ne $newMode ) {
        if ( $newMode == $tc_modes{al} ) {
            $out .= chr($tc_modes{ps}) if !( $curMode == $tc_modes{ml} or $curMode == $tc_modes{pl} );
        } elsif ( $newMode == $tc_modes{pl} ) {
            $out .= chr($tc_modes{ml}) if $curMode != $tc_modes{ml};
        } elsif  ( $curMode == $tc_modes{pl} ) {
            $out .= chr($tc_modes{al});
        }
        $out .= chr($newMode);
    }
    $curMode = $newMode if $newMode != $tc_modes{as} and $newMode != $tc_modes{ps};

    $out .= $item->[1];
  }
  return $out;
}

my %candModeSecond = (
    $tc_modes{al} => $tc_modes{ps},
    $tc_modes{ll} => $tc_modes{ps},
    $tc_modes{ml} => $tc_modes{ps},
    $tc_modes{pl} => $tc_modes{al},
);

sub _compact_text($;$$$$) {
  my ($t,$latch,$curMode,$shiftFollows,$fast) = @_;
  $latch //= 1;
  $shiftFollows ||= 0;
  my $preshift = $curMode;
  my @out = ( $latch ? (900) : () );

  $curMode //= $tc_modes{al};
  my $shiftMode = undef;

  die "sanity: $curMode cannot be shifted mode" if $curMode == $tc_modes{as} || $curMode == $tc_modes{ps};

  my $preencode = _preencode_text($t,$fast,$curMode);
  while ( $preencode =~ m/(.)(.|$)/g ) {
    my ($first,$second) = ($1,$2);
    if ( $second eq '' ) { # Final
      my $candMode = ( $first =~ m/[$tc_ModeSwitch]/ ) ? $first : $curMode;
      # FIXME: Some of these should never actually happen
      $second = chr( $candModeSecond{$candMode} ) // die "sanity: uknown";
    }
    my $codepoint = 0;
    foreach my $chr ( $first, $second ) {
      $codepoint = $codepoint*30 + ( $tc_ModePoint{$shiftMode // $curMode}{$chr} // die "sanity: " . ord($chr) . " $curMode $shiftMode" );
      $shiftMode = undef;
      if ( ord($chr) == $tc_modes{as} || ord($chr) == $tc_modes{ps} ) {
        $shiftMode = ord($chr);
      } elsif ( $chr =~ m/[$tc_ModeSwitch]/ ) {
        $curMode = ord($chr);
      }
    }
    push @out,$codepoint;
  }

  return \@out;
}

sub _compact_number($;$) {
  my ($t,$latch) = @_;
  die "sanity: '$t' is not numeric" unless $t =~ m/^\d+$/;
  $latch //= 1;

  my @codewords;
  while ( length($t) ) {
    my $tIn = substr($t,0,44);
    $t = length($t) > 44 ? substr($t,44) : ""; 
    push @codewords, @{_compact_number_raw($tIn)};
  }
  return [ ( $latch ? (902) : () ) ,@codewords];
}

sub _compact_number_raw($) {
  my ($t) = $_[0];
  die "sanity: '$t' is not numeric" unless $t =~ m/^\d+$/;
  die "sanity: trying to compact '$t', which is '" . length($t) . "' digits long. Expected <=44"
    unless length($t) <= 44;
  $t = "1$t";

  use bigint;
  my @codewords;
  while ($t != 0) { 
    unshift @codewords, $t % 900;
    $t = int( $t/900 );
  }
  return \@codewords;
}

# FIXME: Reverse this algorithm so the final reverse of @E is not needed
sub _ec_codewords($$) {
  my ($codewords,$level) = @_;
  my $n = @$codewords;
  my $k = 2**($level+1);
  die "sanity: input string is empty\n" if $n == 0;
  die "sanity: length not correct\n" if $n != $codewords->[0];
  die "sanity: invalid level $level\n" if $level < 0 || $level > 8;
  my $A = $Barcode::PDF417::PP_Tables::coeff[$level];
  my @E = map { 0 } 1 .. $k;

  my ($t1,$t2,$t3);
  for ( my $i = 0; $i < @$codewords; ++$i ) {
    $t1 = ( $codewords->[$i] + $E[-1] ) % 929;
    for ( my $j = $k-1; $j >= 0; --$j ) {
      $t2 = ($t1 * $A->[$j]) % 929;
      $t3 = 929 - $t2;
      $E[$j] = ( ( $j > 0 ? $E[$j-1] : 0 ) + $t3 ) % 929;
    }
  }
  return [ map { $_ == 0 ? 0 : 929 - $_ } reverse @E ];
}

sub _row_codewords($$$$) {
  my ($F,$r,$c,$s) = @_;
  my $k = $F % 3;
  die "sanity: $k out of range\n" if $k < 0 || $k > 2;
  my $lr = 30 * int( ($F-1)/3 ) + (
    $k == 0 ? int( ($r - 1)/3 ) :
    $k == 1 ? ( $s * 3 + ($r-1)%3 ) :
              ( $c - 1 ) );
  my $rr = 30 * int( ($F-1)/3 ) + (
    $k == 0 ? ($c - 1) :
    $k == 1 ? int( ($r-1)/3 ) :
              ( ($s * 3) + ($r-1) % 3 ) );
  die "sanity: $lr out of range\n" if $lr < 0 or $lr >= 989;
  die "sanity: $rr out of range\n" if $rr < 0 or $lr >= 989;
  return ($lr,$rr);
}

sub _measure_symbol($$$$) {
  my ($r,$c,$ec,$m) = @_;
  die "sanity: r $r out of bounds\n" if $r < 3 || $r > 90;
  die "sanity: c $c out of bounds\n" if $c < 1 || $c > 30;

  my $n = $c*$r - 2**($ec+1);
  die "cannot fit EC\n" if $n < 0;

  my $pad = $n-$m-1;
  die "cannot fit code\n" if $pad < 0;

  return ($n,$pad);
}

sub _pad_codewords($$$) {
  my ($codewords, $n, $pads) = @_;
  return [ $n, @$codewords, ( map { 900 } (1..$pads) ) ];
}

sub _final_codewords($$$$) {
  my ($codewords,$r,$c,$ec) = @_;

  my ($n,$pads) = _measure_symbol($r,$c,$ec,$#$codewords + 1);
  $codewords = _pad_codewords($codewords,$n,$pads);
  my $ecWords = _ec_codewords($codewords,$ec);

  my @toPlace = ( @$codewords,@$ecWords );
  return \@toPlace;
}

sub _build_symbol($$$$) {
  my ($codewords,$nR,$nC,$ec) = @_;
  my $toPlace = _final_codewords($codewords,$nR,$nC,$ec);
  return _build_symbol_raw($toPlace,$nR,$nC,$ec);
}

sub _build_symbol_raw($$$$) {
  my ($toPlace,$nR,$nC,$ec) = @_;
  my @outData;
  my $idx = 0;
  for ( my $r = 0; $r < $nR; ++$r ) {
    my ($lr,$rr) = _row_codewords($r,$nR,$nC,$ec);
    my $k = $r % 3;

    my $rowData = $startSymbol . $Barcode::PDF417::PP_Tables::codewords[$lr][$k];
    for (my $c = 0; $c < $nC; ++$c ) {
      $rowData .= $Barcode::PDF417::PP_Tables::codewords[$toPlace->[$idx++]][$k];
    }
    push @outData, $rowData . $Barcode::PDF417::PP_Tables::codewords[$rr][$k] . $endSymbol;
  }
  return \@outData;
}

1;
