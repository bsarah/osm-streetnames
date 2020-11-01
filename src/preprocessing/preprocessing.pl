#!/usr/bin/perl -w

#call: preprocessing.pl inlist outfolder outfile

#this program receives a list of url with files to download and then processes all the files and stores the resulting files in outfolder

#infile entries: download.geofabrik.de/europe/austria-latest.osm.pbf

#outfile is a log of the run

use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';



my $infile = shift;
my $outfolder = shift;
my $outfile = shift;
#path to scripts
my $scripts = "/homes/biertank/bsarah/Documents/projects/osm/scripts";


open(my $outf,">>",$outfile);

open FA,"<$infile" or die "can't open $infile\n";
#binmode FA, ':utf8';
while(<FA>){
    chomp;
    my $line=$_;
    if($line =~ /^#/){next;}
    my @F = split "\/", $line;
    my $file = $F[-1];
    my @G = split '-', $file;
    my @Gname = @G[0 .. scalar @G-2];
    my $country = join('-',@Gname);
    print $outf "$country\n";
    #download file
    my $wgcmd = "wget $line";
    my @out0 = readpipe("$wgcmd");
    print $outf "wget\n";
    #osmium pipeline
    my $hfile = "highways-in-$country\.osm.pbf";
    my $osmcmd = "osmium tags-filter $file w/highway -o $hfile";
    my @out1 = readpipe("$osmcmd");
    print $outf "osmium filter\n";
    my $hfile2 = "highways-in-$country\.osm.bz2";
    my $osmcmd2 = "osmium cat $hfile -o $hfile2";
    my @out2 = readpipe("$osmcmd2");
    print $outf "osmium cat\n";
    #perl scripts
    my $streetfile = "$outfolder\/03a_streets-in-$country\.tsv";
    my $nodefile = "$outfolder\/03b_nodes-in-$country\.tsv";
    my $wtablecmd = "bzcat $hfile2 | perl $scripts\/writeTable.pl - $streetfile $nodefile";
    my @out3 = readpipe("$wtablecmd");
    print $outf "writeTable \n";
    #distances
    my $distfile = "$outfolder\/04_streets-in-$country\_dists.tsv";
    my $distcmd = " perl $scripts\/addDistances.pl $streetfile $nodefile $distfile";
    my @out4 = readpipe("$distcmd");
    print $outf "addDistances\n";
    #python script
    my $sortfile = "$outfolder\/05_streets-in-$country\_dists_sorted.tsv";
    my $pycmd = "python3 $scripts\/uniquify.py -i $distfile -o $sortfile";
    my @out5 = readpipe("$pycmd");
    print $outf "uniquify\n";
    #files 5andhalf for unique street entries
    my $fiveandhalf = "$outfolder\/05andhalf_streets-in-$country\_dists_unique.tsv";
    my $cmd55 = "perl $scripts/uniqueStreets.pl $distfile $sortfile $fiveandhalf";
    my @out55 = readpipe("$cmd55");
    for(my $i5=0;$i5<scalar @out55;$i5++){
	print $outf "$out55[$i5]";
    }
    #again perl, nameProps, does the same as uniqueStreets but doesn't print unique street entries
    my $mpfile = "$outfolder\/06_streets-in-$country\_nameprops_midpoints.tsv";
    my $mpcmd = "perl $scripts\/nameProps.pl $distfile $sortfile $mpfile";
    my @out6 = readpipe("$mpcmd");
    print $outf "nameProps\n";
    for(my $i=0;$i<scalar @out6;$i++){
	print $outf "$out6[$i]";
    }
    print $outf "\n";
    #addTokens
    my $termfile = "$outfolder\/07a_terms-in-$country\_nameprops.tsv";
    my $tokfile = "$outfolder\/07b_tokens-in-$country\_nameprops.tsv";
    my $tokcmd = "perl $scripts\/addTokens.pl $mpfile $termfile $tokfile";
    my @out7 = readpipe("$tokcmd");
    print $outf "terms and tokens\n $out7[0] $out7[1]\n";
    #filtering
    my $fixfilter = "$outfolder\/08a_terms-in-$country\_nameprops_filtered_fix.tsv";
    my $comfilter = "$outfolder\/08b_terms-in-$country\_nameprops_filtered_com.tsv";
    my $filcmd = "perl $scripts\/filterTerms.pl $termfile $mpfile $fixfilter $comfilter";
    my @out8 = readpipe("$filcmd");
    print $outf "filtering\n";
    for(my $j=0;$j<scalar @out8;$j++){
	print $outf "$out8[$j]";
    }
    print $outf "\n";
    #addClasses
    my $fixfilter2 = "$outfolder\/09a_terms-in-$country\_nameprops_filtered_fix.tsv";
    my $comfilter2 = "$outfolder\/09b_terms-in-$country\_nameprops_filtered_com.tsv";
    my $filcmd2 = "perl $scripts\/addClasses.pl $fixfilter $fixfilter2";
    my $filcmd3 = "perl $scripts\/addClasses.pl $comfilter $comfilter2";
    my @out9a = readpipe("$filcmd2");
    chomp(@out9a);
    print $outf "Classes for fix terms:\n";
    print $outf "$out9a[0]\n";
    my @out9b = readpipe("$filcmd3");
    chomp(@out9b);
    print $outf "Classes for composed terms:\n";
    print $outf "$out9b[0]\n";
    #rm cmds
    my $rmcmd = "rm $file $hfile $hfile2";
    readpipe("$rmcmd");
}
