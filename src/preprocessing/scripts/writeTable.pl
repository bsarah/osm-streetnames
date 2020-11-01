#!/usr/bin/perl -w

#call: perl writeTable.pl streets_in_X.osm streets-in-X.tsv nodes-in-X.tsv


#this program will take a highways-in-...-.osm as input and output a table listing all highways with types primary, secondary, tertiary, residential, unclassified and corresponding information

#rewrite osm highway files into tables with
#way_id, street name, num_coordinate_points or list of nodes refs, central_coordinate, street_type, ref_number or way_id, maxspeed, oneway, ref or official_ref, lit?

#<way id=""
#nd ref=
#k="name" v=""
#k="highway" v=""
#k="maxspeed" v=""
#k="oneway" v=""
#k="ref" v=""
#k="official_ref" v=""
#k="lit" v=""

#ways seem to be uniquely stored with an id
#only take ways with a name!
#create two tables, one with all the nodes and one with all the ways and node ref numbers, then the program which needs coordinates can check


#store all nodes with id and coordinates:  <node id="99887" lat="51.5255026" lon="-0.1510675"/>
#nodes are either directly ended by />. if this is not the case, there will be some more information and the node entry is ended by </node>

#highways seem to be of type 'way'
#  <way id="73">
#    <nd ref="195825"/>
#    <nd ref="196069"/>
#    <tag k="abutters" v="mixed"/>
#    <tag k="highway" v="primary"/>
#    <tag k="lit" v="yes"/>
#    <tag k="maxspeed" v="30 mph"/>
#    <tag k="name" v="Ballards Lane"/>
#    <tag k="oneway" v="yes"/>
#    <tag k="ref" v="A598"/>
#    <tag k="surface" v="asphalt"/>
#  </way>
#nd ref are nodes references that can are coordinates


use Data::Dumper;
use strict;
use warnings;
use utf8;
binmode STDOUT, ':utf8';


my $infile = shift;
my $streetfile = shift;
my $nodefile = shift;

open(my $outf, ">>", $streetfile);
open(my $outn, ">>", $nodefile);

#my $nodeopen = 0; #opened a node tag
my $wayopen = 0; #opened a way tag
my $curwid = "NA";
my @curreflist = ();
my $curname = "NA";
my $curtype = "NA";
my $curspeed = "NA";
my $curoneway = "NA";
my $curref = "NA"; #ref or official ref
my $curlit = "NA";


my $wheader = "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tNumNodes\tNodeIDs\n";
print $outf $wheader;
my $nheader = "NodeID\tLat\tLon\n";
print $outn $nheader;

my $dot = "\.";
my $tick = "\'";
my $comma = "\,";
my $ob = "\(";
my $cb = "\)";
my $sc = "\;";
my $qm = "\?";
my $slash = "\/";
my $feet = "\"";
my $em = "\!";
my $dd = "\:";
my $mi = "\-";
my $us = "\_";
my $lt = "\<";
my $gt = "\>";
my $hash = "\#";
my $spac = " ";
my $and = "\&";
my $dollar = "\$";

open FA,"<$infile" or die "can't open $infile\n";
#binmode FA, ':utf8';
while(<FA>){
    chomp;
    my $line=$_;
    $line =~ s/^\s+//; #remove whitespaces at the beginning of the line
    if($line =~ /^<node/){
	my @F = split " ", $line;
	my $id;
	my $lon;
	my $lat;
	for(my $i=0;$i<scalar @F; $i++){
	    if($F[$i] =~ /^id/){
		$id = substr($F[$i],4,-1);
		$id =~ s/\Q$feet\E//g;
	    }
	    if($F[$i] =~ /^lat/){
		$lat = substr($F[$i],5,-1);
	    }
	    if($F[$i] =~ /^lon/){
		$lon = substr($F[$i],5,-3);
	    }
	}
	print $outn "$id\t$lat\t$lon\n";
    }
    elsif($line =~ /^<way id/){
	$wayopen = 1;
	my @L = split " ", $line;
	#<way id=""
	$curwid = substr($L[1],4,-1);
	$curwid =~ s/\Q$feet\E//g;
#	print STDERR "$curwid\n";
    }
    elsif($wayopen == 1){
	if($line =~ /^<nd ref/){
	    my $nid = substr($line,9,-3);
#	    print STDERR "node ref $nid\n";
	    push @curreflist, $nid;
	}
	if($line =~ /^<tag/){
#	    print STDERR "start with tag\n";
	    my @G = split " ", $line;
	    
	    my $kval = substr($G[1],3,-1);
	    my @vvals = @G[2 .. $#G];
	    my $vvalstr = join(" ",@vvals);
	    my $vval = substr($vvalstr,3,-3);
	    #print STDERR "kval: $kval vval: $vval\n";
	    if($kval =~ /^name$/){
		#remove special characters?
		#e.g. man&apos;s
		$curname = lc($vval);
		$curname =~ s/\Q$dot\E//g;
		$curname =~ s/\Q$tick\E//g;
		$curname =~ s/\Q$comma\E//g;
		$curname =~ s/\Q$ob\E//g;
		$curname =~ s/\Q$cb\E//g;
		$curname =~ s/\Q$sc\E//g;
		$curname =~ s/\Q$qm\E//g;
		$curname =~ s/\Q$slash\E//g;
		$curname =~ s/\Q$feet\E//g;
		$curname =~ s/\Q$em\E//g;
		$curname =~ s/\Q$dd\E//g;
		#$curname =~ s/\Q$mi\E//g;
		$curname =~ s/\Q$us\E//g;
		$curname =~ s/\Q$lt\E//g;
		$curname =~ s/\Q$gt\E//g;
		$curname =~ s/\Q$hash\E//g;
		#$curname =~ s/\Q$spac\E//g;
		$curname =~ s/\Q$and\E//g;
		$curname =~ s/\Q$dollar\E//g;
	    }
	    if($kval =~ /^highway$/){
		$curtype = $vval;
	    }
	    if($kval=~ /^maxspeed$/){
		if($vval =~ /^[0-9]+/){
		    $curspeed = $vval;
		}
	    }
	    if($kval =~ /^oneway$/){
		$curoneway = $vval;
	    }
	    if($kval =~ /^ref$/ || $kval =~ /^official_ref$/){
		$curref = $vval;
	    }
	    if($kval =~ /^lit$/){
		$curlit = $vval;
	    }
	}
	if($line =~ /way>$/){
	    $wayopen = 0;
#	    print STDERR "close way\n";
#	    print STDERR "$curwid\t$curname\t$curtype\t$curspeed\t$curoneway\t$curref\t$curlit\n";
	    if(($curtype eq "primary" || $curtype eq "secondary" || $curtype eq "tertiary" || $curtype eq "residential" || $curtype eq "unclassified" || $curtype eq "pedestrian") && $curname ne "NA" && $curname ne ""){
		#write line in table
		#	"StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tNumNodes\tNodeIDs\n";
		my $numnodes = scalar @curreflist;
		my $nodes = join(",",@curreflist);
		binmode(STDOUT, ":utf8");
		print $outf "$curwid\t$curname\t$curtype\t$curspeed\t$curoneway\t$curref\t$curlit\t$numnodes\t$nodes\n";
	    }
	    $curwid = "NA";
	    @curreflist = ();
	    $curname = "NA";
	    $curtype = "NA";
	    $curspeed = "NA";
	    $curoneway = "NA";
	    $curref = "NA"; #ref or official ref
	    $curlit = "NA";
	}
    }
    else{}
}

