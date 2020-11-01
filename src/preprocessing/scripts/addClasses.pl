#!/usr/bin/perl -w

#perl addClasses.pl infile1 newoutfile1


#this program just calculates averages for av locality and mp locality and for each term, add the class number (1,2,3,4) at the end of the line

#inheader: Term    numprefix       numinfix        numsuffix       numcomplete     numnames        occurences      type_predictability     main_type       av_length       av_locality     mp_locality     midPointLat     midPointLon

#outheader: Term    numprefix       numinfix        numsuffix       numcomplete     numnames        occurences      type_predictability     main_type       av_length       av_locality     mp_locality     class  perc  midPointLat     midPointLon

use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

my $infile = shift;
my $outfile = shift;

my $header = "Term\tnumprefix\tnuminfix\tnumsuffix\tnumcomplete\tnumnames\toccurences\ttype_predictability\tmain_type\tav_length\tav_locality\tmp_locality\tclass\toccperc\tvipperc\tmidPointLat\tmidPointLon\n";

open(my $outf,">>",$outfile);
print $outf $header;

my %term2line = ();
my $mplocsum = 0;
my $avlocsum = 0;
my $occsum = 0;
my $num = 0;

my @S10 = split '\/', $infile;
my @S1 = split '_', $S10[-1];
my $numind = $S1[0];
my @S1a = split '-', $S1[1];
#print STDERR "country $S1[1]\n";
my @names1 = @S1a[2 .. scalar @S1a-1];
my $country = join('-',@names1);

open FA,"<$infile" or die "can't open $infile\n";
while(<FA>){
    chomp;
    my $line=$_;
    if($line =~ /^Term/){next;}
    my @F = split "\t", $line;
    my $term = $F[0];
    $num++;
    $mplocsum+=$F[-3];
    $avlocsum+=$F[-4];
    $occsum+=$F[6];
    $term2line{$term} = $line;
}

my $avmplocsum =  0;
my $avavlocsum = 0;
my $avoccsum = 0;
if($num > 0){
    $avmplocsum = sprintf("%.3f",$mplocsum/$num);
    $avavlocsum =  sprintf("%.3f",$avlocsum/$num);
    $avoccsum =  sprintf("%.3f",$occsum/$num);
}
my $avoccperc = 0;
if($occsum > 0){
    $avoccperc = sprintf("%.5f",$avoccsum/$occsum);
}
#print "avmploc: $avmplocsum\nav avloc: $avavlocsum\nav occurence: $avoccsum\n percentage of average occurence: $avoccperc\n";

print "$country\t$numind\t$avmplocsum\t$avavlocsum\t$avoccsum\t$avoccperc\n";

foreach my $k (keys %term2line){
    my @F = split "\t", $term2line{$k};
    my $class1 = 0;
    if($F[-3] >= $avmplocsum){ #class 1 or 3
	if($F[-4] >= $avavlocsum){ #class 1
	    $class1 = 1;
	}
	else{#class 3
	    $class1 = 3;
	}
    }
    else{#class 2 or 4
	if($F[-4] >= $avavlocsum){ #class 2
	    $class1 = 2;
	}
	else{#class 4
	    $class1 = 4;
	}
    }
    my $vipperc = sprintf("%.3f",$F[6]/$num);
    my $occperc = sprintf("%.5f",$F[6]/$occsum);
    my $tmpval = $F[-3];
    $F[-3] = "$tmpval\t$class1\t$occperc\t$vipperc";
    my $outstr = join("\t", @F);
    binmode(STDOUT, ":utf8");
    print $outf "$outstr\n";
}
