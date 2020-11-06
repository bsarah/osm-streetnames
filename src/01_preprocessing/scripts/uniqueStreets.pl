#!/usr/bin/perl -w

#call: perl uniqueStreets.pl 04file 05file 05andhalf.tsv


#this program creates a list such as the one in the 04_infile, except that now, each node appears in at most one street entry (with one street id) and we calculate midpoints for that street.
#this reduces the number of streets such that each street appears only once!



#format:
#04
#StreetID	StreetName	StreetType	MaxSpeed	OneWay	StreetRef	StreetLit	medLat	medLon	streetLength	NumNodes	NodeIDs
#05
#StreetName	1	StreetID,

#outfile: 05andhalf
#StreetID	StreetName	StreetType	MaxSpeed	OneWay	StreetRef	StreetLit	midPointLat	midPointLon	streetLength	NumNodes	NodeIDs StreetIDs

#street id: the ID combining most of the nodes is kept, all the others are written as a list in the last column
use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';
use List::Util qw( min max );
use Math::Trig;


my $infile1 = shift;
my $infile2 = shift;
my $outfile = shift;

my %id2line = (); #street id to entry in 04 file

open FA,"<$infile1" or die "can't open $infile1\n";
while(<FA>){
    chomp;
    my $line=$_;
    if($line =~ /^StreetID/){next;}
    my @F = split "\t", $line;
    my $id = $F[0];
    if(exists($id2line{$id})){
	print STDERR "StreetID $id already exists!\n";
    }
    else{
	$id2line{$id} = $line;
    }
}


my $header = "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tmidPointLat\tmidPointLon\tstreetLength\tNumNodes\tNodeIDs\tStreetIDs\n";
open(my $outf,">>",$outfile);
print $outf $header;

open FB,"<$infile2" or die "can't open $infile2\n";
while(<FB>){
    chomp;
    my $line=$_;
    if($line =~ /^StreetName/){next;}
    my @F = split "\t", $line;
    my @IDS = split ',', $F[-1];
    if(exists($id2line{$IDS[0]})){}
    else{print "StreetID $id2line{$IDS[0]} does not exists!\n";}
    my @G = split "\t", $id2line{$IDS[0]};
    my $name = $G[1];
    my $maxid = $G[0];
    my $maxnodes = $G[-2];
    my %nodes = ();
    my @N = split ',', $G[-1];
    for(my $n=0;$n<scalar @N;$n++){
	$nodes{$N[$n]} =1;
    }
    my $type = $G[2]; #try to remove 'unclassified' if it happens
    my $maxspeed = $G[3]; #try to remove 'NA'
    my $oneway = $G[4]; #try to remove 'NA'
    my $ref = $G[5]; #try to remove 'NA'
    my $lit = $G[6]; #try to remove 'NA'
    my $latsum = $G[7];
    my $lonsum = $G[8];
    my $lensum = $G[9];
    for(my $i=1;$i<scalar @IDS;$i++){
	if(exists($id2line{$IDS[$i]})){}
	else{print "StreetID $id2line{$IDS[$i]} does not exists!\n";}
	my @H = split "\t", $id2line{$IDS[$i]};
	if($H[-2] > $maxnodes){
	    $maxid = $H[0];
	    $maxnodes = $H[-2];
	}
	my @M = split ',', $H[-1];
	for(my $m=0;$m<scalar @M;$m++){
	    if(exists($nodes{$M[$m]})){$nodes{$M[$m]} += 1;}
	else{$nodes{$M[$m]} = 1;}
	}
	if($type eq "NA"){$type = $H[2];}
	elsif($type eq "unclassified" && $H[2] ne "NA"){$type = $H[2];}
	else{}
	if($maxspeed eq "NA"){$maxspeed = $H[3];}
	if($oneway eq "NA"){$oneway = $H[4];}
	if($ref eq "NA"){$ref = $H[5];}
	if($lit eq "NA"){$lit = $H[6];}
	$latsum += $H[7];
	$lonsum += $H[8];
	$lensum += $H[9];
    }
    #create new entry for this street
    my $numids = scalar @IDS;
    my $midlat = sprintf("%.3f",$latsum/$numids);
    my $midlon = sprintf("%.3f",$lonsum/$numids);
    my $midlen = sprintf("%.3f",$lensum/$numids);
    my $idstr = join(",",@IDS);
    my $nodestr = join(",",keys %nodes);
    my $numnodes = scalar (keys %nodes);
    binmode(STDOUT, ":utf8");
    my $outline = "$maxid\t$name\t$type\t$maxspeed\t$oneway\t$ref\t$lit\t$midlat\t$midlon\t$midlen\t$numnodes\t$nodestr\t$idstr\n";
    print $outf $outline;
}
