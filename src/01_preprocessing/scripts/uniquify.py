import igraph as ig
import argparse

#call: python uniquify.py streets-in-X_dists.tsv unique_names.outlist

#input format:
#my $wheader = "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tmedLat\tmedLon\tstreetLength\tNumNodes\tNodeIDs\n";


#output names of really unique streets (no overlapping nodes) is just a list
#output table:
#my $wheader = "StreetID\tStreetName\tStreetType\tMaxSpeed\tOneWay\tStreetRef\tStreetLit\tmedLat\tmedLon\tstreetLength\tNumNodes\tNodeIDs\tnumParts\tidListOtherParts\n";

#add number of distinct id's the street is composed of and add a list of other ids to the table

#if streets with the same name do not overlap, check distances :)
#check distances will be done in the next step

#for each name, create a hash: name-> list of ids

#use python, create a graph and get connected components


parser = argparse.ArgumentParser()
parser.add_argument("-i", "--infile")
parser.add_argument("-o", "--outfile") #graphfile
args = parser.parse_args()

inputfile = ""
if args.infile:
    inputfile = args.infile
else:
    print("no inputfile given!\n")
    exit
outputfile = ""
if args.outfile:
    outputfile = args.outfile
else:
    outputfile = inputfile+"sorted.tsv"
f = open(outputfile, 'w')

d = dict() #street name -> idlist
t = dict() #street id -> node list
file = open(inputfile,"r")
for iline in file:
    fline = iline.rstrip()
    fwords = fline.split("\t")
    t[fwords[0]] = fwords[-1]
    sname = fwords[1]
    if sname in d:
        d[sname] = d[sname]+","+str(fwords[0])
    else:
        d[sname] = str(fwords[0])

dlen = len(d)

for k in d: #k is street name
    ids = d[k].split(",")  #list of ids with street name k
    ilen = len(ids)
    if ilen == 1:
        #directly write in table, no graph necessary
        outstr = k+"\t"+str(1)+"\t"+str(ids[0])+","
        f.write(outstr+'\n')
    g = ig.Graph()
    n = dict() #nodes
    for i in range(0,len(ids)-1):
        curnode = ids[i] #one node id with street name k, streetid curnode
        if curnode not in n:
            g.add_vertex(curnode)
            kid = g.vs.find(curnode)
            n[curnode]=kid
        kid = g.vs.find(curnode)
        idlist = t[curnode].split(",") #this is the coordinate nodes for street with id curnode and name k
        cnodeslen = len(idlist)
        for j in range(i+1,len(ids)):#for each street curnode, check if its nodes in idlist overlap with nodes of other streets with ids in ids
            othernode = ids[j]#next node with street name k and streetid othernode
            if othernode not in n:
                g.add_vertex(othernode)
                oid = g.vs.find(othernode)
                n[othernode] = oid
            oid = g.vs.find(othernode)
            otheridlist = t[othernode].split(",")
            com = set(idlist).intersection(otheridlist)
            intersectlen = len(com)
            if len(com) > 0:
                g.add_edge(kid,oid)
    gvslen = len(g.vs)
    gcom = g.components()
    glen = len(gcom)
    #print connected components as groups of verteices (ids of streets)
    for c in gcom:
        bc = g.induced_subgraph(c)
        bcnames = bc.vs['name']
        bcnum = len(bc.vs)
        outstr2 = k+"\t"+str(bcnum)+"\t"
        for vn in bcnames:
            outstr2 = outstr2+str(vn)+","
        f.write(outstr2+'\n')
