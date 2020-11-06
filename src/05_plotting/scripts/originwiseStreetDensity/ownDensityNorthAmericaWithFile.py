import argparse
import pandas as pd
from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Polygon
from sklearn.neighbors import KernelDensity
import copy
from matplotlib.colors import LogNorm

#always check for names of columns in the input!

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--infile")#list of 05andhalf files!
parser.add_argument("-t","--topfolder")
parser.add_argument("-a","--alle") #just create plot for all streets if 1 and no street given
parser.add_argument("-f","--sfile") #normalize the street occurences in this file, which could be the 13file 
parser.add_argument("-c", "--coords") #coordinates file
parser.add_argument("-o", "--outfile")

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

dostreets = 0
streetfile = ""
if args.sfile:
    streetfile = args.sfile
    dostreets = 1
printcoords = 0
coordfile = ""
if args.coords:
    coordfile = open(args.coords,"w")
    printcoords = 1
else:
    print("no coordinates file given!\n")
    exit
outputfile = ""
if args.outfile:
    outputfile = args.outfile
else:
    outputfile = inputfile+".pdf"
outputlist = ""



if streetfile == "" and allstreets == 0:
    print("you have to set -a to 1 or specify a streetname or streetfile!\n")
    exit


if streetfile != "" and allstreets == 1:
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

streetsum = 0
specstreetsum = 0

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
        if min(lons) < minlon:
            minlon = min(lons)
        if max(lons) > maxlon:
            maxlon = max(lons)
        if min(lats) < minlat:
            minlat = min(lats)
        if max(lats) > maxlat:
            maxlat = max(lats)
        #fill grid
        for i in range(len(lats)):
            curlat = lats[i]
            curlon = lons[i]
            intlat = int(abs(curlat*10))
            intlatrounded = int((intlat - intlat % 5)/10 * 2)
            intlon = int(abs(curlon*10))
            intlonrounded = int((intlon - intlon % 5)/10 * 2)
            cgrid[intlatrounded][intlonrounded]+=1


coord2names = dict()
coord2coords = dict()
streets2 = pd.read_csv(streetfile,sep='\t',header=0)
lats2 = streets2['midPointLat'].values
lons2 = streets2['midPointLon'].values
streetnames2 = streets2['StreetName'].values
#fill grid
for i in range(len(lats2)):
    curlat = lats2[i]
    curlon = lons2[i]
    curname = streetnames2[i]
    intlat = int(abs(curlat*10))
    intlatrounded = int((intlat - intlat % 5)/10 * 2)
    intlon = int(abs(curlon*10))
    intlonrounded = int((intlon - intlon % 5)/10 * 2)
    coordkey = str(intlatrounded) + "_" + str(intlonrounded)
    realcoords = str(curlat) + "_" + str(curlon)
    if coordkey in coord2names:
        coord2names[coordkey] = str(coord2names[coordkey]) + ";" + str(curname)
        coord2coords[coordkey] = str(coord2coords[coordkey]) + ";" + str(realcoords)
    else:
        coord2names[coordkey] = str(curname)
        coord2coords[coordkey] = str(realcoords)
    sgrid[intlatrounded][intlonrounded]+=1

dlen = len(coord2names)
print(dlen)

    
print(len(alllats))
print(len(alllons))

print(latrange)
print(lonrange)
print(minlat,maxlat, minlon,maxlon)

lats2plot = []
lons2plot = []

#normalize and mirror!
ncgrid = np.zeros((latrange,lonrange))
for i in range(latrange):
    for j in range(lonrange):
        if dostreets == 0:
            ncgrid[179-i][359-j] = np.log(0.000005+cgrid[i][j]/streetsum) # ncgrid[89-i][179-j]
        if dostreets == 1:
            ncgrid[179-i][359-j] = np.log(0.000005)
            if cgrid[i][j] > 0:
                ncgrid[179-i][359-j] = np.log(0.000005 + sgrid[i][j]/cgrid[i][j])
                if printcoords == 1 and sgrid[i][j]>2 and ncgrid[179-i][359-j] > -4:
                    origlat = (i)/2
                    origlon = (-1)*(j)/2
                    coordkey = str(i) + "_" + str(j)
                    streetstr = ""
                    cstr = ""
                    if coordkey in coord2names:
                        streetstr = str(coord2names[coordkey])
                        cstr = str(coord2coords[coordkey])
                    coordfile.write(str(origlat) + "\t" + str(origlon) + "\t" + str(sgrid[i][j]) + "\t" + str(cgrid[i][j]) + "\t" + str(ncgrid[179-i][359-j]) + "\t" + streetstr + "\t" + cstr)
                    coordfile.write("\n")

#the projection is still not perfect but currently the best option
#m=Basemap(projection='mill',llcrnrlon=-180, urcrnrlon=0,llcrnrlat=0,urcrnrlat=90)
m=Basemap(projection='mill',llcrnrlon=-130, urcrnrlon=-60,llcrnrlat=15,urcrnrlat=55)
m.drawparallels(np.arange(-90.,90.,15.),labels=[1,0,0,0],dashes=[2,2],color='gray',linewidth=0.2)
m.drawmeridians(np.arange(-180.,180.,20.),labels=[0,0,0,1],dashes=[2,2],color='gray',linewidth=0.2)
m.drawcoastlines(color='gray',linewidth=0.5)
m.drawstates(color='gray',linewidth=0.3)
m.drawcountries(color='gray',linewidth=0.5)

my_cmap = plt.get_cmap('rainbow')
my_cmap.set_under('white')

ylon = np.arange(90,0,-0.5)
xlat = np.arange(-180,0,0.5)
px ,py = np.meshgrid(xlat,ylon)
x, y = m(px,py)

minval = np.log(0.000006)
if dostreets == 1:
    minval = np.log(0.000006)

c = m.pcolormesh(x,y,ncgrid,cmap=my_cmap,vmin=minval)
m.colorbar(c, extend = 'min')


plt.savefig( outputfile)
plt.close('all')
