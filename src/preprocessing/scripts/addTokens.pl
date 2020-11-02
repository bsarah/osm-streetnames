#!/usr/bin/perl -w

#call: perl addTokens.pl streetsfile outfile1(terms) outfile2(tokens)

#this program will split street names at " " and "-" to produce street terms.
#these terms will be used to split street names into tokens
#terms and tokens will be counted and stored in outfiles


use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

my $infile = shift;
my $outfile = shift;
my $outfile2 = shift;

#infile format "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tNumNodes\tNodeIDs\n";

#last name (generic) = term, e.g. street, lane, road
#pre name (specific) = name of the street, e.g., main, railway, einstein, maple
#my $header = "StreetID\tStreetName\tStreetPreName\tStreetLastName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tNumNodes\tNodeIDs\n";

#smaller input file: nameprops, streets with same name are summarized
#format: StreetName	occurences	type_predictability	main_type	length_predictability	av_length	locality(av pairwise distance)


my $header = "Term\tnumprefix\tnuminfix\tnumsuffix\tnumcomplete\tnumnames\n";
my $header2 = "Token\tnumprefix\tnumsuffix\n";

open(my $outf,">>", $outfile);
open(my $outf2,">>", $outfile2);
print $outf $header;
print $outf2 $header2;

my %terms2num = (); #only put single terms and how often they appeared, thus only if split was possible
my %uniqsplits = ();#add sinlge words (no space or -) uniquely, also names that weren't split
my $issplit = 0;
my $numunsplit = 0;
my $numsplit = 0;
open FA,"<$infile" or die "can't open $infile\n";
while(<FA>){
    chomp;
    my $line=$_;
    if($line =~ /^StreetID/){next;}
    if($line =~ /^StreetName/){next;}
    my @F = split "\t", $line;
    my $street = lc($F[0]);
    my $occs = $F[1];
    my @G = split " ", $street;
    if(scalar @G > 1){
	$issplit = 1;
	for(my $g=0;$g<scalar @G;$g++){
	    if(length($G[$g]) <= 1){next;}
	    my @Gsub = split '-', $G[$g];
	    if(scalar @Gsub > 1){
		for(my $gs=0;$gs<scalar @Gsub;$gs++){
		    if(length($Gsub[$gs]) <= 1){next;}
		    if(exists($terms2num{$Gsub[$gs]})){
			$terms2num{$Gsub[$gs]}+=$occs;
		    }
		    else{
			$terms2num{$Gsub[$gs]}=$occs;
		    }
		    if(exists($uniqsplits{$Gsub[$gs]})){$uniqsplits{$Gsub[$gs]}+=$occs;}
		    else{$uniqsplits{$Gsub[$gs]}=$occs;}
		}
	    }
	    else{
		if(exists($terms2num{$G[$g]})){
		    $terms2num{$G[$g]}+=$occs;
		}
		else{
		    $terms2num{$G[$g]}=$occs;
		}
		if(exists($uniqsplits{$G[$g]})){$uniqsplits{$G[$g]}+=$occs;}
		else{$uniqsplits{$G[$g]}=$occs;}
	    }
	}
    }
    else{
	my @H = split '-', $street;
	if(scalar @H > 1 && scalar @G == 1){
	    $issplit = 1;
	    for(my $h=0;$h<scalar @H;$h++){
		if(length($H[$h]) <= 1){next;}
		if(exists($terms2num{$H[$h]})){
		    $terms2num{$H[$h]}+=$occs;
		}
		else{
		    $terms2num{$H[$h]}=$occs;
		}
		if(exists($uniqsplits{$H[$h]})){$uniqsplits{$H[$h]}+=$occs;}
		else{$uniqsplits{$H[$h]}=$occs;}
	    }
	}
    }
    if($issplit == 0){
	$numunsplit++;
	if(exists($uniqsplits{$street})){$uniqsplits{$street}+=$occs;}
	else{$uniqsplits{$street}=$occs;}
    }
    else{
	$numsplit++;
	$issplit = 0;
    }
}

#split into prefix and suffix and infix!
my %subterms2num = ();
my %preterms2num = ();
my %interms2num = ();
my %all2num = ();
#store the remaining parts of the names, too
my %suftokens2num = ();
my %pretokens2num = ();

my @names = keys %uniqsplits;

my @terms = keys %terms2num;
for(my $i=0;$i<scalar @names;$i++){
    my $curname = $names[$i];
    my $curcount = $uniqsplits{$curname};
    for(my $t=0;$t<scalar @terms;$t++){
	my $curterm = $terms[$t];
	if(length($curterm) <= 1){next;}
	if($curterm eq $curname){
	    if(exists($all2num{$curterm})){
		$all2num{$curterm}+=$curcount;
	    }
	    else{
		$all2num{$curterm}=$curcount;
	    }
	    next;
	}
	my $ind = index($curname,$curterm);
	if($ind == -1){next;}
	if($ind == 0){ #term = prefix
	    if(exists($preterms2num{$curterm})){
		$preterms2num{$curterm}+=$curcount;
	    }
	    else{
		$preterms2num{$curterm}=$curcount;
	    }
	    #get suffix:
	    my $suftoken = substr($curname,length($curterm));
	    $suftoken =~ s/^\s+//; #remove space in front
	    if(length($suftoken) <= 1){next;}
	    #try to remove a connecting letter
	    my $suftoken2 = substr($curname,length($curterm)+1);
	    $suftoken2 =~ s/^\s+//; #remove space in front
	    #check first if suffix or subsuffix exists in uniquely splitted terms
	    if(exists($terms2num{$suftoken})){
		if(exists($suftokens2num{$suftoken})){
		    $suftokens2num{$suftoken}+=$curcount;
		}
		else{
		    $suftokens2num{$suftoken}=$curcount;
		}
	    }
	    elsif(exists($terms2num{$suftoken2}) && length($suftoken2) > 1){
		if(exists($suftokens2num{$suftoken2})){
		    $suftokens2num{$suftoken2}+=$curcount;
		}
		else{
		    $suftokens2num{$suftoken2}=$curcount;
		}
	    }
	    else{
		if(exists($suftokens2num{$suftoken})){
		    $suftokens2num{$suftoken}+=$curcount;
		}
		else{
		    $suftokens2num{$suftoken}=$curcount;
		}
	    }
	}
	elsif($ind > 0 && $ind + length($curterm) >= length($curname)){
	    #term = suffix
	    if(exists($subterms2num{$curterm})){
		$subterms2num{$curterm}+=$curcount;
	    }
	    else{
		$subterms2num{$curterm}=$curcount;
	    }
	    #find prefix
	    my $pretoken = substr($curname,0,$ind);
	    $pretoken =~ s/^\s+//; #remove space in front
	    if(length($pretoken) <= 1){next;}
	    #try to remove a connecting letter
	    my $pretoken2 = substr($curname,0,$ind-1);
	    $pretoken2 =~ s/^\s+//; #remove space in front
	    if(exists($terms2num{$pretoken})){
		if(exists($pretokens2num{$pretoken})){
		    $pretokens2num{$pretoken}+=$curcount;
		}
		else{
		    $pretokens2num{$pretoken}=$curcount;
		}
	    }
	    elsif(exists($terms2num{$pretoken2}) && length($pretoken2) > 1){
		if(exists($pretokens2num{$pretoken2})){
		    $pretokens2num{$pretoken2}+=$curcount;
		}
		else{
		    $pretokens2num{$pretoken2}=$curcount;
		}
	    }
	    else{
		if(exists($pretokens2num{$pretoken})){
		    $pretokens2num{$pretoken}+=$curcount;
		}
		else{
		    $pretokens2num{$pretoken}=$curcount;
		}
	    }
	}
	else{#term is inside
	    if(exists($interms2num{$curterm})){
		$interms2num{$curterm}+=$curcount;
	    }
	    else{
		$interms2num{$curterm}=$curcount;
	    }
	    #find outside terms
	    my $intoken1 = substr($curname,0,$ind);
	    my $intoken2 = substr($curname,$ind+length($curterm));
	    my $intoken12 = substr($curname,0,$ind-1);
	    my $intoken22 = substr($curname,$ind+length($curterm)+1);
	    $intoken1 =~ s/^\s+//; #remove space in front
	    $intoken2 =~ s/^\s+//; #remove space in front
	    $intoken12 =~ s/^\s+//; #remove space in front
	    $intoken22 =~ s/^\s+//; #remove space in front
	    if(length($intoken1)>1){
		if(exists($terms2num{$intoken1})){
		    if(exists($pretokens2num{$intoken1})){
			$pretokens2num{$intoken1}+=$curcount;
		    }
		    else{
			$pretokens2num{$intoken1}=$curcount;
		    }
		}
		elsif(exists($terms2num{$intoken12}) && length($intoken12) > 1){
		    if(exists($pretokens2num{$intoken12})){
			$pretokens2num{$intoken12}+=$curcount;
		    }
		    else{
			$pretokens2num{$intoken12}=$curcount;
		    }
		}
		else{
		    if(exists($pretokens2num{$intoken1})){
			$pretokens2num{$intoken1}+=$curcount;
		    }
		    else{
			$pretokens2num{$intoken1}=$curcount;
		    }
		}
	    }
	    if(length($intoken2)>1){
		if(exists($terms2num{$intoken2})){
		    if(exists($suftokens2num{$intoken2})){
			$suftokens2num{$intoken2}+=$curcount;
		    }
		    else{
			$suftokens2num{$intoken2}=$curcount;
		    }
		}
		elsif(exists($terms2num{$intoken22}) && length($intoken22) > 1){
		    if(exists($suftokens2num{$intoken22})){
			$suftokens2num{$intoken22}+=$curcount;
		    }
		    else{
			$suftokens2num{$intoken22}=$curcount;
		    }
		}
		else{
		    if(exists($suftokens2num{$intoken2})){
			$suftokens2num{$intoken2}+=$curcount;
		    }
		    else{
			$suftokens2num{$intoken2}=$curcount;
		    }
		}
	    }
	}
    }
}

my @prekeys = keys %pretokens2num;
my @sufkeys = keys %suftokens2num;
my $pnum = scalar @prekeys;
my $snum = scalar @sufkeys;


my @tkeys = sort { $terms2num{$a} <=> $terms2num{$b} } keys(%terms2num);
for(my $tk=scalar @tkeys-1;$tk>=0;$tk--){
    my $tkey = $tkeys[$tk];
    my $numpref = 0;
    my $numsuf = 0;
    my $numin = 0;
    my $numall = 0;
    if(exists($preterms2num{$tkey})){$numpref = $preterms2num{$tkey};}
    if(exists($subterms2num{$tkey})){$numsuf = $subterms2num{$tkey};}
    if(exists($interms2num{$tkey})){$numin = $interms2num{$tkey};}
    if(exists($all2num{$tkey})){$numall = $all2num{$tkey};}
    binmode(STDOUT, ":utf8");
    print $outf "$tkey\t$numpref\t$numin\t$numsuf\t$numall\t$terms2num{$tkey}\n";
}


#print new tokens based on splits that do not appear by themselves
my %tokens2num = ();
foreach my $pt (keys %pretokens2num){
    if(exists($tokens2num{$pt})){
	$tokens2num{$pt}+=$pretokens2num{$pt};
    }
    else{
	$tokens2num{$pt}=$pretokens2num{$pt};
    }
#    $tokens2lines{$pt} = "$pt\t$pretokens2num{$pt}";
}
foreach my $st (keys %suftokens2num){
    if(exists($tokens2num{$st})){
	$tokens2num{$st}+=$suftokens2num{$st};
    }
    else{
	$tokens2num{$st}=$suftokens2num{$st};
    }
}


my @tokkeys = sort { $tokens2num{$a} <=> $tokens2num{$b} } (keys %tokens2num);
for(my $to=scalar @tokkeys-1;$to>=0;$to--){
    binmode(STDOUT, ":utf8");
    my $curkey = $tokkeys[$to];
    my $numpret = 0;
    my $numsuft = 0;
    if(exists($pretokens2num{$curkey})){
	$numpret = $pretokens2num{$curkey};
    }
    if(exists($suftokens2num{$curkey})){
	$numsuft = $suftokens2num{$curkey};
    }
    print $outf2 "$curkey\t$numpret\t$numsuft\n";
}

print "number of unsplit tokens: $numunsplit\n";
print "number of split tokens: $numsplit\n";

