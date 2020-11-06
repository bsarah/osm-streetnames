#!/usr/bin/perl -w

#call filterTerms.pl terms-in-X.tsv streets-in-X-nameprops_midpoints.tsv outfileTerms outfileTermNames

#input1 = output of addTokens.pl
#input1 format: "term\tnumprefix\tnuminfix\tnumsuffix\tnumcomplete\tnumnames\n";

#input2 = output of nameProps.pl
#input2 format: StreetName  occurences type_predictability main_type length_predictability av_length? locality(av pairwise distance) midpointlat midpointlon


#lift analysis to the next level, from street names to street terms
#this program will remove all streets with all numbers <= 1 in input1
#then input2 is scanned for the current term and a midpoint is calculated
#and type predictability
#and average length
#and locality between midpoints

#similar to nameProps but now on term level

#locality and new midpoint and av length have to be calculated in a weighted fashion

#what happens with names that are term and name at the same time?
#keep, count and print


#outfile format:
# "Term\tnumprefix\tnuminfix\tnumsuffix\tnumcomplete\tnumnames\ttype_predictability main_type av_length locality(av pairwise mitpoint distance) midpointlat midpointlon


use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';
use List::Util qw( min max );
use Math::Trig;

my $infile = shift;
my $infile2 = shift;
my $outfile = shift;
my $outfile2 = shift;


open(my $outf, ">>", $outfile);
open(my $outf2, ">>", $outfile2);

my $header = "Term\tnumprefix\tnuminfix\tnumsuffix\tnumcomplete\tnumnames\toccurences\ttype_predictability\tmain_type\tav_length\tav_locality\tmp_locality\tmidPointLat\tmidPointLon\n";

print $outf $header;
print $outf2 $header;

my %term2line = (); #omit terms with all numbers <= 1

my $numtermandname = 0;
my $numkeep = 0;
my $numthrow = 0;
my $numjustcomplete = 0;

open FA,"<$infile" or die "can't open $infile\n";
while(<FA>){
    chomp;
    my $line=$_;
    if($line =~ /^Term/){next;}
    my @F = split "\t", $line;
    my $term = $F[0];
    my $dokeep = 0;
    for(my $i=1;$i<scalar @F;$i++){
	if($F[$i] > 2){$dokeep = 1; last;}
    }
    if($dokeep == 1){
	$term2line{$term} = $line;
	$numkeep++;
    }
    else{
	$numthrow++;
    }
    if($F[4] != $F[5]){
	$numtermandname++;
    }
    if($F[1] == 0 && $F[2] == 0 && $F[3] == 0 && $F[4] > 0){
	$numjustcomplete++;
    }
}

print "streets being term and name: $numtermandname\n";
print "number of streets only occuring as complete term: $numjustcomplete\n";
print "number of streets kept: $numkeep\n";
print "number of streets filtered out: $numthrow\n";

#read input2
my %name2line = ();

open FA2,"<$infile2" or die "can't open $infile2\n";
while(<FA2>){
    chomp;
    my $line=$_;
    if($line =~ /^StreetID/){next;}
    if($line =~ /^StreetName/){next;}
    my @F = split "\t", $line;
    my $name = lc($F[0]);
    $name2line{$name} = $line;
}

#street types: primary, secondary, tertiary, residential, unclassified, pedestrian
##no for each term, go through all of the street names in inputfile2 and calculate all the numbers
my @terms = keys %term2line;
my @names = keys %name2line;

for(my $i=0;$i<scalar @terms;$i++){
    my $curterm = $terms[$i];
    my @lats = ();
    my $latsum = 0;
    my @lons = ();
    my $lonsum = 0;
    my @lens = ();
    my $lensum = 0;
    my @occs = (); #weighting
    my $occsum = 0;
    my @types = ();
    my @tpreds = ();
    my @locs = ();
    my $locsum = 0;
    for(my $j=0;$j<scalar @names;$j++){
	my $curname = $names[$j];
	my $ind = index($curname,$curterm);
	if($ind == -1){next;}
	my @F = split "\t", $name2line{$curname};
	push @occs, $F[1];
	$occsum += $F[1];
	push @tpreds, $F[2];
	push @types, $F[3];
	push @lens, $F[5];
	$lensum += ($F[1] * $F[5]);
	push @locs, $F[6];
	if($F[6] ne "NA"){
	    $locsum += ($F[1] * $F[6]);
	}
	push @lats, $F[7];
	$latsum += ($F[1] * $F[7]);
	push @lons, $F[8];
	$lonsum += ($F[1] * $F[8]);
    }
    ##calculate type predictability
    my $prisum = 0;
    my $prinum = 0;
    my $secsum = 0;
    my $secnum = 0;
    my $tersum = 0;
    my $ternum = 0;
    my $ressum = 0;
    my $resnum = 0;
    my $uncsum = 0;
    my $uncnum = 0;
    my $pednum = 0;
    my $pedsum = 0;
    my $weirdnum = 0;
    for(my $n=0;$n<scalar @occs;$n++){
	if($types[$n] eq "primary"){
	    $prinum+=$occs[$n];
	    $prisum+=$occs[$n]*$tpreds[$n];
	}
	elsif($types[$n] eq "secondary"){
	    $secnum+=$occs[$n];
	    $secsum+=$occs[$n]*$tpreds[$n];
	}
	elsif($types[$n] eq "tertiary"){
	    $ternum+=$occs[$n];
	    $tersum+=$occs[$n]*$tpreds[$n];
	}
	elsif($types[$n] eq "residential"){
	    $resnum+=$occs[$n];
	    $ressum+=$occs[$n]*$tpreds[$n];
	}
	elsif($types[$n] eq "unclassified"){
	    $uncnum+=$occs[$n];
	    $uncsum+=$occs[$n]*$tpreds[$n];
	}
	elsif($types[$n] eq "pedestrian"){
	    $pednum+=$occs[$n];
	    $pedsum+=$occs[$n]*$tpreds[$n];
	}
	else{
	    $weirdnum++;
	}
    }
    if($weirdnum > 0){
	print STDERR "$weirdnum weird streets for term $curterm!\n";
    }
    
    my $pripred = 0;
    if($prinum > 0){$pripred = sprintf("%.3f",$prisum/$prinum);}
    my $secpred = 0;
    if($secnum > 0){$secpred = sprintf("%.3f",$secsum/$secnum);}
    my $terpred = 0;
    if($ternum > 0){$terpred = sprintf("%.3f",$tersum/$ternum);}
    my $respred = 0;
    if($resnum > 0){$respred = sprintf("%.3f",$ressum/$resnum);}
    my $uncpred = 0;
    if($uncnum > 0){$uncpred = sprintf("%.3f",$uncsum/$uncnum);}
    my $pedpred = 0;
    if($pednum > 0){$pedpred = sprintf("%.3f",$pedsum/$pednum);}
    my $maintype = "primary";
    my $mainpred = $pripred;
    if($secpred > $mainpred){$maintype = "secondary"; $mainpred = $secpred;}
    if($terpred > $mainpred){$maintype = "tertiary"; $mainpred = $terpred;}
    if($respred > $mainpred){$maintype = "residential"; $mainpred = $respred;}
    if($uncpred > $mainpred){$maintype = "unclassified"; $mainpred = $uncpred;}
    if($pedpred > $mainpred){$maintype = "pedestrian"; $mainpred = $pedpred;}
    #length
    if($occsum == 0){print STDERR "occsum 0 for $curterm!\n"; next;}
    my $avlen = sprintf("%.3f",$lensum/$occsum);
    #new midpoint
    my $midlat = sprintf("%.3f",$latsum/$occsum);
    my $midlon = sprintf("%.3f",$lonsum/$occsum);
    #av locality
    my $avloc = sprintf("%.3f",$locsum/$occsum);
    #midpoint locality
    my $distsum = 0;
    my $distnum = 0;
    for(my $la=0;$la<scalar @lats-1;$la++){
	for(my $lo=$la+1;$lo<scalar @lats;$lo++){
	    $distnum++;
	    my $dist = FlatDist($lats[$la],$lons[$la],$lats[$lo],$lons[$lo]);
	    $distsum+=$dist;
	}
    }
    my $avdist = 0;
    if($distnum > 0){$avdist = sprintf("%.3f",$distsum/$distnum);}
    my $outline = "$term2line{$curterm}\t$occsum\t$mainpred\t$maintype\t$avlen\t$avloc\t$avdist\t$midlat\t$midlon\n";

    my @G = split "\t", $term2line{$curterm};
    if($G[1] == 0 && $G[2] == 0 && $G[3] == 0 && $G[4] > 0){
	#terms = complete names
	binmode(STDOUT, ":utf8");
	print $outf2 $outline;
    }
    else{
	#terms = pre-, in- or suffix
	binmode(STDOUT, ":utf8");
	print $outf $outline;
    }

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

