#!/usr/bin/perl -w

#call: perl classifyTerms.pl concat_09a_09b list_european_summary_files 11aoutfile_street_prenames 11boutfile_street_kinds 11coutfile_nonclassified

#this program takes a list of terms and tokens of a north american country and searches for exact matches for each term in the european term lists
#for each term, a weight is set for each match with a european country, weight of 0 is not listed, however, they are written in a different file, 11c

#infile:
#10_xxx
#format:
#Term    numprefix       numinfix        numsuffix       numcomplete     numnames        occurences      type_predictability_list        main_type_list  av_length       av_locality     mp_locality     occperc numRegions midPointLat     midPointLon

#and:
#09a_xxx
#09b_xxx
#format:
#Term    numprefix       numinfix        numsuffix       numcomplete     numnames        occurences      type_predictability     main_type       av_length       av_locality     mp_locality     class   occperc vipperc    midPointLat     midPointLon

#outfile format:
#Term    numprefix       numinfix        numsuffix       numcomplete     numnames        occurences      type_predictability_list        main_type_list  av_length       av_locality     mp_locality     occperc numRegions midPointLat     midPointLon num_regions [regions] [weights]

use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';
use List::Util qw( min max );
use Math::Trig;

my $infile = shift;
my $inlist = shift;
my $minocc = shift; #streets to be included in the analysis have to have an occperc which is at least as big as minocc
my $outfile = shift; #for street prenames
my $outfile2 = shift; #for street kinds
my $outfile3 = shift; #for nonclassified street terms

my $kindocc = 0.01; #if a term occurs with >= kindocc in at least one countries with matches, it will be define as a street kind and written in an extra file

my %term2line = (); #term and its line as given in the infile
my %term2regions = (); #term to list of regions with exact matches, separated by _
my %term2weights = (); #term to weights for each region, separated by _
my %term2num = (); #term to number of regions with exact matches
my $termsum = 0; #all terms checked
my $termmatch = 0; #terms where a match has been found
my %term2occ = ();


open(my $outf3,">>",$outfile3);

#american terms
open FA,"<$infile" or die "can't open $infile\n";
while(<FA>){
    chomp;
    my $line = $_;
    if($line =~ /^Term/){print $outf3 "$line\n"; next;}
    my @F = split "\t", $line;
    my $curterm = $F[0];
    #omit this term if it only consists out of numbers and no letters                                                                                                                                                                     
    if($curterm =~ /[\p{L}]+/){} #like /[A-Za-z]/                                                                                                                                                                                         
    else{next;}
    if($F[-4] < $minocc){next;}
    $term2line{$curterm} = $line;
    $termsum++;
    $term2occ{$curterm} = $F[-4];
}

my %term2type = (); #prename 0 or kind 1

open FC,"<$inlist" or die "can't open $inlist\n";
while(<FC>){
    chomp;
    my $curfile=$_;
    my @K = split '_', $curfile;
    my $region = $K[-2];#substr($K[-1],0,-4);
    open FB,"<$curfile" or die "can't open $curfile\n";
    while(<FB>){
	chomp;
	my $line=$_;
	if($line =~ /^Term/){next;}
	my @F = split "\t", $line;
	my $curterm = $F[0]; #european term
	if($F[-4] < $minocc){next;}
	foreach my $k (keys %term2line){
	    if($curterm eq $k){
		$termmatch++;
		my $ttype = 0;
		if($F[-4] >= $kindocc || $term2occ{$k} >= $kindocc){ #it is enough if one of them occurs very frequently
		    $ttype = 1;
		}
		if(exists($term2regions{$curterm})){
		    $term2regions{$curterm} = "$term2regions{$curterm}\_$region";
		    $term2weights{$curterm} = "$term2weights{$curterm}\_$F[-4]";
		    $term2num{$curterm} += 1;
		    if($ttype == 1){$term2type{$curterm} = $ttype;}
		}
		else{
		    $term2regions{$curterm} = $region;
		    $term2weights{$curterm} = $F[-4];
		    $term2num{$curterm} = 1;
		    $term2type{$curterm} = $ttype;
		}

	    }
	}
    }
}

my @matchterms = keys %term2regions;
my $nummatchterms = scalar @matchterms;

open(my $outf,">>",$outfile);
my $header = "Term\tnumMatches\tCountries\tWeights\n";
print $outf $header;

open(my $outf2,">>",$outfile2);
print $outf2 $header;


foreach my $t (keys %term2regions){
    my $outline = "$t\t$term2num{$t}\t$term2regions{$t}\t$term2weights{$t}\n";
    if($term2type{$t} == 1){
	print $outf2 $outline;
    }
    else{
	print $outf $outline;
    }
}

my $unmatched = 0;

#terms that were not matched, thus do not appear in term2region
foreach my $y (keys %term2line){
    if(exists($term2regions{$y})){next;}
    print $outf3 "$term2line{$y}\n";
    $unmatched++;
}

