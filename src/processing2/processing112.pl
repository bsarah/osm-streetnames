#!/usr/bin/perl -w

#call: processing112.pl list_111a_files(with folders) topfolder

#this script runs summarize111ac.pl for all 111a and corresponding 111c files which returns 112 files
#and then runs classifyStreets.pl with the corresponding 05andhalf and 112 files and returns 12_file for each american state


#inlist entry format:
#canada/111a_classifyPrenames_alberta_alleuro_mino000001.tsv

#corresponding 111c files:
#canada/111c_unclassified_alberta_alleuro_mino000001.tsv



#summarize111ac
#perl ../scripts/summarize111ac.pl 111a_classifyPrenames_quebec_alleuro_mino000001.tsv 111c_unclassified_quebec_alleuro_mino000001.tsv 112_classifiedTerms_quebec_alleuro_mino000001.tsv


#classifyStreets
#perl ../scripts/classifyStreets.pl 05andhalf_streets-in-quebec_dists_unique.tsv 112_classifiedTerms_quebec_alleuro_mino000001.tsv 12_classifiedStreets_quebec_alleuro_mino000001.tsv


use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';

my $inlist = shift;
my $infolder = shift;

#path to scripts
my $scripts = "/homes/biertank/bsarah/Documents/projects/osm/scripts";

open FA,"<$inlist" or die "can't open $inlist\n";
#binmode FA, ':utf8';
while(<FA>){
    chomp;
    #get corresponding files
    my $afile=$_;
    my @F = split '\/', $afile;
    my $folder = $F[0];
    my @G = split "_", $F[1];
    my $country = $G[2];
    my $cfile = "$folder\/111c_unclassified_$country\_$G[3]\_$G[4]";
    #summarize
    my $file112 = "$folder\/112_classifiedTerms\_$country\_$G[3]\_$G[4]";
    my $sumcmd = "perl $scripts\/summarize111ac.pl $afile $cfile $file112";
    readpipe("$sumcmd");
    #classifyStreets
    my $file05 = "$folder\/05andhalf_streets-in-$country\_dists_unique.tsv";
    my $file12 = "$folder\/12_classifiedStreets_$country\_$G[3]\_$G[4]";
    my $classcmd = "perl $scripts\/classifyStreets.pl $file05 $file112 $file12";
    readpipe("$classcmd");
}
