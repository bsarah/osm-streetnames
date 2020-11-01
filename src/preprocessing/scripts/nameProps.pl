#!/usr/bin/perl -w

#call: perl nameProps.pl 04streets-in-X_dists.tsv 05streets-in-X_dists_sorted.pl outtable

#format:
#StreetID	StreetName	StreetType	MaxSpeed	OneWay	StreetRef	StreetLit	medLat	medLon	streetLength	NumNodes	NodeIDs

#StreetName	1	StreetID,

#outfile:
#StreetName  occurences type_predictability length_predictability av_length? locality(av pairwise distance) midpointlat midpointlon



#additional output:

#count streets
#count number of distinct street names
#count unique street names (occurence == 1)
# -> calculate naming creativity and uniqueness for this country

#output max and min values for each column

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

my %id2type = ();
my %id2lat = ();
my %id2lon = ();
my %id2len = ();

open FA,"<$infile1" or die "can't open $infile1\n";
while(<FA>){
    chomp;
    my $line=$_;
    if($line =~ /^StreetID/){next;}
    my @F = split "\t", $line;
    $id2type{$F[0]} = $F[2];
    $id2lat{$F[0]} = $F[7];
    $id2lon{$F[0]} = $F[8];
    $id2len{$F[0]} = $F[9];
}

#StreetName  occurences type_predictability length_predictability av_length? locality(av pairwise distance)
my $header = "StreetName\toccurences\ttype_predictability\tmain_type\tlength_predictability\tav_length\tlocality(av pairwise distance)\tmidPointLat\tmidPointLon\n";
open(my $outf, ">>", $outfile);
print $outf $header;

my $numuniq = 0;
my $numstreets = 0;
my $numnames = 0;

my $curname = "";
my $curnum = 0;
my %type2num = ();
my %name2num = ();
my %name2line = ();
my %name2midpoint = ();
my @lats = ();
my @lons = ();
my @lens = ();

my $maxdist = 0;
my $mindist = 1000000;

open FB,"<$infile2" or die "can't open $infile2\n";
while(<FB>){
    chomp;
    my $line=$_;
    if($line =~ /^StreetName/){next;}
    $numstreets++;
    my @F = split "\t", $line;
    my $name = $F[0];
    if(exists($name2num{$name})){
	$name2num{$name}+=1;
    }
    else{
	$name2num{$name}=1;
    }
    my @IDS = split ',', $F[2];
    #calculate the current midpoint
    my $tmplatsum = 0;
    my $tmplonsum = 0;
    my $numpresentids = 0;
    for(my $t=0;$t<scalar @IDS;$t++){
#	if(exists($id2lat{$IDS[$t]})){
	    $tmplatsum += $id2lat{$IDS[$t]};
	    $tmplonsum += $id2lon{$IDS[$t]};
#	    $numpresentids++;
	#}
    }
    my $tmpmidlon = sprintf("%.3f",$tmplonsum/(scalar @IDS));
    my $tmpmidlat = sprintf("%.3f",$tmplatsum/(scalar @IDS));

    my $tmpnumids = scalar @IDS;
    #print STDERR "num: $tmpnumids lat: $tmpmidlat lon: $tmpmidlon \n";
    
    if($curname ne "" && $curname ne $name){
	#finish that name and set a new one
	$numnames++;
	#types
	my @K = keys %type2num;
	if($curnum == 1){
	    $numuniq++;	    
	    my $outline = "$curname\t$curnum\t1\t$K[0]\t1\t$lens[0]\tNA\t$tmpmidlat\t$tmpmidlon\n";
	    $name2line{$curname} = $outline;
#	    print $outf $outline;
	}
	else{
	    my $maxtype = "";
	    my $maxval = 0;
	    foreach my $k (@K){
		if($type2num{$k} > $maxval){
		    $maxval = $type2num{$k};
		    $maxtype = $k;
		}
	    }
	    my $typeprec =  sprintf("%.3f", $maxval/$curnum);
	    #lengths
	    my $lensum = 0;
	    my $s = 0;
	    my $m = 0;
	    my $l = 0;
	    my $xl = 0;
	    foreach my $sl (@lens){
		$lensum += $sl;
		if($sl < 0.33){$s++;}
		elsif($sl < 0.66){$m++;}
		elsif($sl < 1.0){$l++;}
		else{$xl++;}
	    }
	    my $avlen = sprintf("%.3f",$lensum/$curnum);
	    my $max0 = max($s,$m);
	    my $max1 = max($l,$xl);
	    my $realmax = max($max0,$max1);
	    my $lenpred = sprintf("%.3f",$realmax/$curnum);
	    #locality
	    my $distsum = 0;
	    my $distnum = 0;
	    for(my $i=0;$i<scalar @lats-1;$i++){
		for(my $j=$i+1;$j<scalar @lats;$j++){
		    $distnum++;
		    my $dist = FlatDist($lats[$i],$lons[$i],$lats[$j],$lons[$j]);
		    $distsum+=$dist;
		}
	    }
	    my $avdist = sprintf("%.3f",$distsum/$distnum);
	    if($avdist > $maxdist){$maxdist = $avdist;}
	    if($avdist < $mindist){$mindist = $avdist;}
	    my $latsum = 0;
	    foreach (@lats) {
		$latsum += $_;
	    }
	    my $curmidlat = sprintf("%.3f",$latsum/(scalar @lats));
	    my $lonsum = 0;
	    foreach (@lons) {
		$lonsum += $_;
	    }
	    my $curmidlon = sprintf("%.3f",$lonsum/(scalar @lons));
	    my $outline = "$curname\t$curnum\t$typeprec\t$maxtype\t$lenpred\t$avlen\t$avdist\t$curmidlat\t$curmidlon\n";
	#    print "$outline";
	    $name2line{$curname} = $outline;
#	    print $outf $outline;
	}
	$curname = "";
	$curnum = 0;
	%type2num = ();
	@lats = ();
	@lons = ();
	@lens = ();
    }
    if($curname eq ""){
	$curname = $name;
    }
    $curnum++;
    my @G = split ',', $F[-1];
    #take always the first of ids
    my $curid = $G[0];
 #   for(my $g = 0;$g<scalar @G;$g++){
#	if(exists($id2lat{$G[$g]})){
#	    my $curid = $G[$g];
#	    last;
#	}
 #   }
 #   if($curid > -1){
    push @lats, $tmpmidlat;#$id2lat{$curid};
    push @lons, $tmpmidlon;#$id2lon{$curid};
    push @lens, $id2len{$curid};
    binmode(STDOUT, ":utf8");
    #print "name lat, lon, len: $curname $id2lat{$curid} $id2lon{$curid} $id2len{$curid}\n";
    my $ty = $id2type{$curid};
    if(exists($type2num{$ty})){
	$type2num{$ty}+=1;
    }
    else{
	$type2num{$ty}=1;
    }
 #   }
}


#do all this one last time:
#finish that name and set a new one
#types
my @K = keys %type2num;
my $latsum = 0;
foreach (@lats) {
    $latsum += $_;
}
my $curmidlat = sprintf("%.3f",$latsum/(scalar @lats));
my $lonsum = 0;
foreach (@lons) {
    $lonsum += $_;
}
my $curmidlon = sprintf("%.3f",$lonsum/(scalar @lons));
if($curnum == 1){
    $numuniq++;	    
    my $outline = "$curname\t$curnum\t1\t$K[0]\t1\t$lens[0]\tNA\t$curmidlat\t$curmidlon\n";
    $name2line{$curname} = $outline;
#    print $outf $outline;
}
else{
    my $maxtype = "";
    my $maxval = 0;
    foreach my $k (@K){
	if($type2num{$k} > $maxval){
	    $maxval = $type2num{$k};
	    $maxtype = $k;
	}
    }
    my $typeprec =  sprintf("%.3f", $maxval/$curnum);
    #lengths
    my $lensum = 0;
    my $s = 0;
    my $m = 0;
    my $l = 0;
    my $xl = 0;
    foreach my $sl (@lens){
	$lensum += $sl;
	if($sl < 0.33){$s++;}
	elsif($sl < 0.66){$m++;}
	elsif($sl < 1.0){$l++;}
	else{$xl++;}
    }
    my $avlen = sprintf("%.3f",$lensum/$curnum);
    my $max0 = max($s,$m);
    my $max1 = max($l,$xl);
    my $realmax = max($max0,$max1);
    my $lenpred = sprintf("%.3f",$realmax/$curnum);
    #locality
    my $distsum = 0;
    my $distnum = 0;
    for(my $i=0;$i<scalar @lats-1;$i++){
	for(my $j=$i+1;$j<scalar @lats;$j++){
	    $distnum++;
	    my $dist = FlatDist($lats[$i],$lons[$i],$lats[$j],$lons[$j]);
	    $distsum+=$dist;
	}
    }
    my $avdist = sprintf("%.3f",$distsum/$distnum);
    if($avdist > $maxdist){$maxdist = $avdist;}
    if($avdist < $mindist){$mindist = $avdist;}

    my $outline = "$curname\t$curnum\t$typeprec\t$maxtype\t$lenpred\t$avlen\t$avdist\t$curmidlat\t$curmidlon\n";
#    print "$outline";
    $name2line{$curname} = $outline;
    #print $outf $outline;
}
print "number of streets: $numstreets\n";
print "number of distinct street names: $numnames\n";
print "number of singleton street names: $numuniq\n";

my $creativity = sprintf("%.3f",$numnames/$numstreets);
print "creativity index: $creativity\n";
my $uniqueness = sprintf("%.3f",$numuniq/$numstreets);
print "uniqueness index: $uniqueness\n";

print "max and min average pairwise distances: $maxdist $mindist\n";

my @topnames = sort { $name2num{$a} <=> $name2num{$b} } keys(%name2num);
for(my $t=scalar @topnames-1;$t>=0;$t--){
    my $nami = $topnames[$t];
    binmode(STDOUT, ":utf8");
    #print "$nami\n";
    print $outf $name2line{$nami};
}


sub FlatDist{
    my @inp = @_;
    my $lat1 = $inp[0];
    my $lon1 = $inp[1];
    my $lat2 = $inp[2];
    my $lon2 = $inp[3];
    my $deltalat = $lat1-$lat2;
    my $deltalon = $lon1-$lon2;
    my $deltalatrad = deg2rad($deltalat);
    my $deltalonrad = deg2rad($deltalon);
    my $R = 6371.009;
    my $medlat = sprintf("%.3f",($lat1+$lat2)/2);
    my $dist = sprintf("%.4f",$R*sqrt($deltalatrad**2 + (cos($medlat)*$deltalonrad)**2));
    return $dist;
}

