#!/usr/bin/perl -w

#call: perl detectClusters.pl 05andhalf_streets-in-state.tsv 112_classify_state_europe_minocc.tsv 12_outfile_street_classifications.tsv


#format infile 05andhalf:
#StreetID StreetName StreetType MaxSpeed OneWay StreetRef StreetLit midPointLat midPointLon streetLength NumNodes NodeIDs StreetIDs

#format infile112
#Term    numMatches      Countries

#format outfile:
#StreetID StreetName StreetType MaxSpeed OneWay StreetRef StreetLit midPointLat midPointLon streetLength NumNodes NodeIDs StreetIDs numMatches Countries


use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';
use List::Util qw( min max );
use Math::Trig;

#add option to skip the creation of intermediate file and instead read an already existing one

my $infile4 = shift;
my $infile11 = shift;
#my $midoutfile = shift;
my $outfile = shift;

my %term2regions = ();
#my %term2weights = ();
my %term2num = ();

open FB,"<$infile11" or die "can't open $infile11\n";
while(<FB>){
    chomp;
    my $line=$_;
    if($line =~ /^Term/){next;}
    my @F = split "\t", $line;
    my $term = $F[0];
    $term2num{$term} = $F[1];
    $term2regions{$term} = $F[2];
}

#my %id2line = ();
#my %id2lat = ();
#my %id2lon = ();
#my %id2cluster = (); #streetid to clusterid
#my %id2regions = ();
#my %id2weights = ();

open(my $outf,">>",$outfile);

open FA,"<$infile4" or die "can't open $infile4\n";
while(<FA>){
    chomp;
    my $line = $_;
    if($line =~ /^StreetID/){print $outf "$line\tnumMatches\tCountries\n"; next;}
    my @F = split "\t", $line;
    my $sid = $F[0];
    my $sname = $F[1];
    my %c2num = (); #countries classifying the street name
    #plsit by space and minus and fill results in G
    my @G = ();
    my @S = split " ", $sname;
    for(my $s = 0;$s<scalar @S;$s++){
	my @M = split '-', $S[$s];
	for(my $m=0;$m<scalar @M;$m++){
	    push @G, $M[$m];
	}
    }
    #check if a term has been classified
    for(my $i=0;$i<scalar @G;$i++){
	foreach my $k (keys %term2num){
	    if($k eq $G[$i]){#classified
		my @R = split "_", $term2regions{$k};
		for(my $r=0;$r<scalar @R;$r++){
		    if(exists($c2num{$R[$r]})){
			$c2num{$R[$r]}+=1;
		    }
		    else{
			$c2num{$R[$r]}=1;
		    }
		}
	    }
	}
    }
    my @C = keys %c2num;
    my $tnum = scalar @C;
    if($tnum > 0){
	my $cstr = join("_", @C);
	print $outf "$line\t$tnum\t$cstr\n";
    }
}




#my $numstreets = scalar (keys %id2line);
#print "number of classified streets: $numstreets\n";
##print exactly this to intermediate output file:
#my $midheader = "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tmedLat\tmedLon\tstreetLength\tNumNodes\tNodeIDs\tRegions\tWeights\n";
#open(my $outmf,">>",$midoutfile);
#print $outmf $midheader;
#foreach my $sid (keys %id2line){
#    my @regs = split "_", $id2regions{$sid};
#    my @wes = split "_", $id2weights{$sid};
#    for(my $i=0;$i<scalar @regs;$i++){
#	print $outmf "$id2line{$sid}\t$regs[$i]\t$wes[$i]\n";
#    }
#}
