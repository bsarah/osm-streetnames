#!/usr/bin/perl -w

#call: perl getStreetsByCountry.pl 12_classifiedStreetsNorthAmerica.txt topfolder european_country 13_northamerica_eurocountry_outfile

#this program goes through all classified streets of north america and collects all entries of streets that were classified to a given european country

#12x file format:
#StreetID StreetName StreetType MaxSpeed OneWay StreetRef StreetLit midPointLat midPointLon streetLength NumNodes NodeIDs StreetIDs numMatches Countries


#outfile format:
#StreetID StreetName StreetType MaxSpeed OneWay StreetRef StreetLit midPointLat midPointLon streetLength NumNodes NodeIDs StreetIDs numMatches Countries original_state_in_north_america



use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';
use List::Util qw( min max );
use Math::Trig;

my $inlist = shift;
my $topfolder = shift;
my $country = shift;
my $outfile = shift;

open(my $outf,">>",$outfile);

#my $numtot = 0;
#my $numcur = 0;

my $hasheader = 0;

open FB,"<$inlist" or die "can't open $inlist\n";
while(<FB>){
    chomp;
    my $curfile=$_;
    #e.g. canada/12_classifiedStreets_alberta_alleuro_mino000001.tsv
    my @C = split "_", $curfile;
    my $state = $C[2];
    open FA,"<$topfolder\/$curfile" or die "can't open $$topfolder\/curfile\n";
    while(<FA>){
	chomp;
	my $line = $_;
	if($line =~ /^StreetID/){
	    if($hasheader ==0 ){
		print $outf "$line\tnumMatches\tCountries\tNAState\n";
		$hasheader = 1;
	    }
	    next;
	}
	#$numtot+=1;
	my @F = split "\t", $line;
	my $streetname = $F[1];
	if($streetname =~ /[0-9]+/){next;}
	my @L = split "_", $F[-1];
	for(my $i=0;$i<scalar @L;$i++){
	    if($L[$i] eq $country){
		print $outf "$line\t$state\n";
		#$numcur+=1;
	    }
	}
    }
}

#print "Total number of streets: $numtot\n";
#print "Selected number of streets: $numcur\n";
