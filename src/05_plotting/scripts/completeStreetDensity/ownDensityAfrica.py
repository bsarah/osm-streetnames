
import argparse
import pandas as pd
from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon
from sklearn.neighbors import KernelDensity
import copy
from matplotlib.colors import LogNorm


def isRealSubstring(superstring, substring):
    curstreets = str(superstring).strip().split(" ")
    for cs in curstreets:
        cslen = len(cs)
        sblen = len(substring)
        if cslen >= sblen:
            ind = str(cs).find(str(substring))
            if ind != -1:
                if ind == 0 and abs(cslen-sblen) != 1:
                    return True
                if ind > 1 and abs((ind+sblen)-cslen) != 1:
                    return True
    return False
            #true for ind == 0 and lengths do not differ by 1
            #true for ind > 1 and ind+len(substring) and len(superstring) do not differ by 1 


parser = argparse.ArgumentParser()
parser.add_argument("-i", "--infile")
parser.add_argument("-t","--topfolder")
parser.add_argument("-a","--alle") #just create plot for all streets if 1 and no street given
parser.add_argument("-f","--sfile") #create density map for all the street names in that file! (first column)
parser.add_argument("-s","--street") #create density map for a certain street name
parser.add_argument("-o", "--outfile")
parser.add_argument("-l", "--outlist") #print all matching street names to check what's happening
parser.add_argument("-c", "--coords") #print all tiles with occurences of target streets and corresponding log density value
args = parser.parse_args()

inputfile = ""
if args.infile:
    inputfile = args.infile
else:
    print("no inputfile given!\n")
    exit
topfolder = ""
if args.topfolder:
    topfolder = args.topfolder
else:
    print("no topfolder given!\n")
    exit
allstreets = 1
if args.alle:
    allstreets = args.alle

streetname = ""
dostreets = 0
if args.street:
    streetname = args.street
    dostreets = 1
streetfile = ""
if args.sfile:
    streetfile = args.sfile
    dostreets = 1
outputfile = ""
if args.outfile:
    outputfile = args.outfile
else:
    outputfile = inputfile+".pdf"
outputlist = ""
debuglist = 0
if args.outlist:
    outputlist = open(args.outlist,"w")
    debuglist = 1
coordinatelist = ""
printcoords = 0
if args.coords:
    coordinatelist = open(args.coords,"w")
    printcoords = 1


    
if streetname == "" and allstreets == 0:
    print("you have to set -a to 1 or specify a streetname or streetfile!\n")
    exit

if streetfile == "" and allstreets == 0:
    print("you have to set -a to 1 or specify a streetname or streetfile!\n")
    exit


if streetname != "" and streetfile != "" and allstreets == 1:
    print("streetname will be added to streetfile and then be used in the analysis!\n")
elif streetname != "" and allstreets == 1:
    print("streetname will be chosen!\n")
elif streetfile != "" and allstreets == 1:
    print("streetfile will be chosen!\n")
else:
    print("start analysis")

    

#create grids to store how many streets occur in this tile
latrange = 90*2
lonrange = 180*2
cgrid = np.zeros((latrange,lonrange))
#this is the grid used to count a certain specified street name
sgrid = np.zeros((latrange,lonrange))


maxlat = -1000
minlat = 1000
maxlon = -1000
minlon = 1000

alllats = []
alllons = []


streetstodo = []
if streetname != "":
    streetstodo.append(streetname)
    
if streetfile != "":
    with open(streetfile) as sf:
        content = sf.readlines()
        for c in content:
            c2 = c.strip('\n')
            splitted = c2.strip().split("\t")
            streetstodo.append(splitted[0])

if dostreets == 1:
    print(len(streetstodo))
            
streetsum = 0
specstreetsum = 0


#coordinates Africa:
#most northern: 37degrees north
#most western 25W or -25
#most eastern: 60E
#most southern: 36south or -36


with open(inputfile) as f:
    content = f.readlines()
    for c in content:
        c2 = c.strip('\n')
        print(topfolder+c2)
        streets = pd.read_csv(topfolder+c2,sep='\t',header=0)
        lats = streets['midPointLat'].values
        lons = streets['midPointLon'].values
        streetnames = streets['StreetName'].values
        cursum = len(lons)
        streetsum += cursum
        alllats.extend(lats)
        alllons.extend(lons)
        #fill grid
        for i in range(len(lats)):
            curlat = lats[i]
            curlon = lons[i]
            intlat = abs(int((curlat+36)*10))           
            intlatrounded = int((intlat - intlat % 5)/10 * 2)
            intlon = abs(int((curlon+30)*10))
            intlonrounded = int((intlon - intlon % 5)/10 * 2)
            cgrid[intlatrounded][intlonrounded]+=1
            if dostreets == 1:
                for straat in streetstodo:
                    if isRealSubstring(streetnames[i],straat):
                        sgrid[intlatrounded][intlonrounded]+=1
                        specstreetsum+=1
                        if debuglist == 1:
                            outputlist.write(str(streetnames[i]) + "\t" + str(straat) + "\t" + c2)
                            outputlist.write("\n")


print(len(alllats))
print(len(alllons))

print(latrange)
print(lonrange)
print(minlat,maxlat, minlon,maxlon)


#normalize and mirror!
ncgrid = np.zeros((latrange,lonrange))
for i in range(latrange):
    for j in range(lonrange):
        if dostreets == 0:
            ncgrid[179-i][j] = np.log(0.000005+cgrid[i][j]/streetsum) # ncgrid[89-i][179-j]
        if dostreets == 1:
            ncgrid[179-i][j] = np.log(0.000005)
            if cgrid[i][j] > 0:
                ncgrid[179-i][j] = np.log(0.000005 + sgrid[i][j]/cgrid[i][j])
                if printcoords == 1:
                    origlat = (i)/2
                    origlon = (j)/2-20
                    coordinatelist.write(str(origlat) + "\t" + str(origlon) + "\t" + str(ncgrid[179-i][j]))
                    coordinatelist.write("\n")

            #ncgrid[89-i][179-j] = np.log(0.01+sgrid[i][j]/specstreetsum) + np.log(0.01+cgrid[i][j]/streetsum)





#coordinates Africa:
#most northern: 37degrees north
#most western 25W or -25
#most eastern: 60E
#most southern: 36south or -36

            
#the projection is still not perfect but currently the best option
m=Basemap(projection='mill',llcrnrlon=-30, urcrnrlon=60,llcrnrlat=-40,urcrnrlat=40)
m.drawparallels(np.arange(-90.,90.,15.),labels=[1,0,0,0],dashes=[2,2],color='gray',linewidth=0.2)
m.drawmeridians(np.arange(-180.,180.,20.),labels=[0,0,0,1],dashes=[2,2],color='gray',linewidth=0.2)
m.drawcoastlines(color='gray',linewidth=0.5)
m.drawstates(color='gray',linewidth=0.3)
m.drawcountries(color='gray',linewidth=0.5)

my_cmap = plt.get_cmap('rainbow')
if dostreets == 1:
    my_cmap = plt.get_cmap('YlOrRd')
my_cmap.set_under('white')

ylon = np.arange(54,-36,-0.5)
xlat = np.arange(-30,150,0.5)
px ,py = np.meshgrid(xlat,ylon)
x, y = m(px,py)

minval = np.log(0.000006)
if dostreets == 1:
    minval = np.log(0.000006)

c = m.pcolormesh(x,y,ncgrid,cmap=my_cmap,vmin=minval)
m.colorbar(c, extend = 'min')


plt.savefig( outputfile)
plt.close('all')
