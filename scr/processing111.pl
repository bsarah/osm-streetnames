#!/usr/bin/perl -w

#call: perl processing111.pl 09alist infolder outputtable

#this program creates and processes the 11x files, that classify street terms based on european streets and the language identification tool

use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';



#workflow:
#concat 09a and 09b files
#perl classifyTerms 09ab_northamerica eurofiles minocc 11a_prenames_out 11b_streetkinds_out 11c_unclassified_out
#python testLanguage.py -i 11a -c 0 -o 111a
#python testLanguage.py -i 11b -c 0 -o 111b
#python testLanguage.py -i 11c -c 1 -o 111c
#write output of testLanguage runs in summarizing output table

my $inlist = shift;
my $infolder = shift;
my $outfile = shift;

#path to scripts
my $scripts = "/homes/biertank/bsarah/Documents/projects/osm/scripts";

open(my $outf,">>",$outfile);
my $header= "Country\tnum11a\tnum11aCorrect\tperc11aCorrect\tnum11aNan\tperc11aNan\tnum11b\tnum11bCorrect\tperc11bCorrect\tnum11bNan\tperc11bNan\tnum11c\tnum11cNan\n";
print $outf $header;

open FA,"<$inlist" or die "can't open $inlist\n";
#binmode FA, ':utf8';
while(<FA>){
    chomp;
    #concatenate files
    my $afile=$_;
    print STDERR "$afile\n";
    #09a_terms-in-alabama_nameprops_filtered_fix.tsv
    my @A = split '_', $afile;
    my @A2 = split '-', $A[1];
    my @Gname = @A2[2 .. scalar @A2-1];
    my $country = "";
    if(scalar @Gname == 1){
	$country = $Gname[0];
    }
    else{
	$country = join('-',@Gname);
    }
    print STDERR "$country\n";
    #09b_terms-in-alabama_nameprops_filtered_com.tsv
    my $bfile = "09b_$A[1]\_$A[2]\_$A[3]\_com.tsv";
    print STDERR "$bfile\n";
    my $cfile = "09ab\_$country\.tsv";
    my $catcmd = "cat $infolder\/$afile $infolder\/$bfile >> $infolder\/$cfile";
    readpipe("$catcmd");
    #run classifyTerms
    my $eurofile = "$scripts/list_euro10files_all.txt";
    my $minocc = 0.000001;
    my $minostr = "000001";
    my $out11a = "$infolder\/11a_classifyPrenames_$country\_alleuro_mino$minostr\.tsv";
    my $out11b = "$infolder\/11b_classifyKinds_$country\_alleuro_mino$minostr\.tsv";
    my $out11c = "$infolder\/11c_unclassified_$country\_alleuro_mino$minostr\.tsv";
    my $classcmd = "perl $scripts\/classifyTerms.pl $infolder\/$cfile $eurofile $minocc $out11a $out11b $out11c";
    readpipe("$classcmd");
    #python scripts
    my $outstr = "$country\t";
    my $out111a = "$infolder\/111a_classifyPrenames_$country\_alleuro_mino$minostr\.tsv";
    my $out111b = "$infolder\/111b_classifyKinds_$country\_alleuro_mino$minostr\.tsv";
    my $out111c = "$infolder\/111c_unclassified_$country\_alleuro_mino$minostr\.tsv";
    my $py1cmd = "python $scripts/testLanguage.py -i $out11a -c 0 -o $out111a";
    my @out1 = readpipe("$py1cmd");
    chomp(@out1);
    my @o11 = split " ", $out1[0];
    my @o12 = split " ", $out1[1];
    my @o13 = split " ", $out1[2];
    my @o14 = split " ", $out1[3];
    my @o15 = split " ", $out1[4];
    $outstr = "$outstr$o11[-1]\t$o12[-1]\t$o14[-1]\t$o13[-1]\t$o15[-1]\t";
    my $py2cmd = "python $scripts/testLanguage.py -i $out11b -c 0 -o $out111b";
    my @out2 = readpipe("$py2cmd");
    chomp(@out2);
    my @o21 = split " ", $out2[0];
    my @o22 = split " ", $out2[1];
    my @o23 = split " ", $out2[2];
    my @o24 = split " ", $out2[3];
    my @o25 = split " ", $out2[4];
    $outstr = "$outstr$o21[-1]\t$o22[-1]\t$o24[-1]\t$o23[-1]\t$o25[-1]\t";
    my $py3cmd = "python $scripts/testLanguage.py -i $out11c -c 1 -o $out111c";
    my @out3 = readpipe("$py3cmd");
    chomp(@out3);
    my @o31 = split " ", $out3[0];
    my @o32 = split " ", $out3[1];
    $outstr = "$outstr$o31[-1]\t$o32[-1]\n";
    print $outf $outstr;
}
