#!/usr/bin/perl -w

#call: summarize111ac.pl 111a 111c outfile

#in formats:
#111a
#Term numMatches Countries Weights Class_Countries Class_Weights Fit

#111c
#Term numMatches Class_Countries Class_Weights

#outfile format:
#Term numMatches Countries

#rules:
#for 111a: always take all the countries that intersect if there is an intersection
#for 111a: if there is no intersection, take the classification based on street terms, as it is mostly names
#for 111c: take the classifications based on the language model
#111b: omit
#omit terms that couldn't be classified


use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';
use List::Util qw( min max );
use Math::Trig;


my $infilea = shift;
my $infileb = shift;
my $outfile = shift;

open(my $outf,">>",$outfile);
my $header = "Term\tnumMatches\tCountries\n";
print $outf $header;



open FA,"<$infilea" or die "can't open $infilea\n";
while(<FA>){
    chomp;
    my $line = $_;
    if($line =~ /^Term/){next;}
    my @F = split "\t", $line;
    my $curterm = $F[0];
    my @C = split "_", $F[2];
    my @L = split "_", $F[4];
    my @R = ();
    my $numm = 0;
    for(my $i=0;$i<scalar @C;$i++){
	my $curc = $C[$i];
	for(my $j =0;$j<scalar @L;$j++){
	    if($curc eq $L[$j]){
		push @R, $curc;
		$numm+=1;
	    }
	}
    }
    my $cstr = "";
    my $numstr = 0;
    if($numm == 0){
	$cstr = join("_",@C);
	$numstr = $F[1];
    }
    else{
	$cstr = join("_",@R);
	$numstr = $numm;
    }
    print $outf "$curterm\t$numstr\t$cstr\n";
}


open FB,"<$infileb" or die "can't open $infileb\n";
while(<FB>){
    chomp;
    my $line = $_;
    if($line =~ /^Term/){next;}
    my @F = split "\t", $line;
    my $curterm = $F[0];
    if($F[1] == 0){next;}
    my @C = split "_", $F[2];
    my %c2num = ();
    for(my $i=0;$i<scalar @C;$i++){
	if(exists($c2num{$C[$i]})){
	    $c2num{$C[$i]}+=1;
	}
	else{
	    $c2num{$C[$i]}=1;
	}
    }
    my @K = keys %c2num;
    my $kstr = join("_",@K);
    my $numk = scalar @K;
    print $outf "$curterm\t$numk\t$kstr\n";
}
