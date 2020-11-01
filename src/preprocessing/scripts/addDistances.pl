#!/usr/bin/perl -w

#call: perl addDistances.pl streets-in-X.tsv nodes-in-X.tsv newstreets-in-X.tsv

#this program will extend the table by adding median coordinates and length of the street
#original header street file "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tNumNodes\tNodeIDs\n";

#format node file: id lat lon

use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';
use Math::Trig;

my $streetfile = shift;
my $nodefile = shift;
my $outfile = shift;

open(my $outf, ">>", $outfile);
my $wheader = "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tmedLat\tmedLon\tstreetLength\tNumNodes\tNodeIDs\n";
print $outf $wheader;

my %id2coord = ();
open FA,"<$nodefile" or die "can't open $nodefile\n";
while(<FA>){
    chomp;
    my $line=$_;
    my @F = split "\t", $line;
    $id2coord{$F[0]} = "$F[1]\t$F[2]";
}


open FB,"<$streetfile" or die "can't open $streetfile\n";
while(<FB>){
    chomp;
    my $line=$_;
    if($line =~ /^StreetID/){next;}
    my @F = split "\t", $line;
    my @P = split ',', $F[-1];
    #take middle node as central point
    my $len = scalar @P;
    if($len == 0){
	binmode(STDOUT, ":utf8");
	print $outf "$F[0]\t$F[1]\t$F[2]\t$F[3]\t$F[4]\t$F[5]\t$F[6]\tNA\tNA\tNA\t$F[7]\t$F[8]\n";
	next;
    }
    if($len == 1){
	if(exists($id2coord{$P[0]})){
	    my @N = split "\t", $id2coord{$P[0]};
	    binmode(STDOUT, ":utf8");
	    print $outf "$F[0]\t$F[1]\t$F[2]\t$F[3]\t$F[4]\t$F[5]\t$F[6]\t$N[0]\t$N[1]\tNA\t$F[7]\t$F[8]\n";
	}
	else{
	    binmode(STDOUT, ":utf8");
	    print $outf "$F[0]\t$F[1]\t$F[2]\t$F[3]\t$F[4]\t$F[5]\t$F[6]\tNA\tNA\tNA\t$F[7]\t$F[8]\n";
	}
	next;
    }
    my $distsum = 0;
    my $curlat = -1;
    my $curlon = -1;
    my $centlat = "NA";
    my $centlon = "NA";
    my $middle = sprintf("%.0f",$len/2);
    #print "mid: $middle len: $len\n";
    for(my $i=0;$i<scalar @P; $i++){
	#print "curlat: $curlat curlon: $curlon distsum: $distsum\n";
	if(exists($id2coord{$P[$i]})){
	    my @N = split "\t", $id2coord{$P[$i]};
	    if($curlat == -1 && $curlon == -1){
		#just set the values
		$curlat = $N[0];
		$curlon = $N[1];
	    }
	    else{
		#calculate the distance between curlat and curlon and values in N, then add distance and set curlat and curlon to new values
		my $deltalat = $curlat-$N[0];
		my $deltalon = $curlon-$N[1];
		my $deltalatrad = deg2rad($deltalat);
		my $deltalonrad = deg2rad($deltalon);
		my $R = 6371.009;
		my $medlat = sprintf("%.3f",($curlat+$N[0])/2);
		my $dist = sprintf("%.4f",$R*sqrt($deltalatrad**2 + (cos($medlat)*$deltalonrad)**2));
		$distsum+=$dist;
		$curlat = $N[0];
		$curlon = $N[1];
		if($i == $middle || ($middle-$i <= 1 && $middle-$i >= 0)){
		    $centlat = $N[0];
		    $centlon = $N[1];
		}
		if($i-$middle <= 1 && $i-$middle >= 0 && $centlat eq "NA"){
		    $centlat = $N[0];
		    $centlon = $N[1];
		}
	    }
	}
    }
    binmode(STDOUT, ":utf8");
    print $outf "$F[0]\t$F[1]\t$F[2]\t$F[3]\t$F[4]\t$F[5]\t$F[6]\t$centlat\t$centlon\t$distsum\t$F[7]\t$F[8]\n";
}
