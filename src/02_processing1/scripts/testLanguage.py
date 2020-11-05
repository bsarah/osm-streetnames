import argparse
import fasttext
import pandas as pd
import numpy as np

#call testLanguage.py wordfile model_path classification_mode outfile


#fasttext needs to be installed and the model accessible
#fasttext can be installed using a conda environment
#model can be downloaded here: https://fasttext.cc/docs/en/language-identification.html
#model name: lid.176.bin
#use the fasttext model and check if north american street terms matched with european street terms result in the same/almost same language

#language abbreviations:
#fr french
#en english
#de german
#bg bulgarian
#cs czech
#da danish
#nl dutch
#et estonian
#fi finnish
#el greek
#hu hungary
#is icelandic
#ga irish
#it italian
#lt lithuanian
#lb luxembourgish
#nn/no norwegian
#pfl palatinate german
#pl polish
#pt portuguese
#ro romanian
#sco scottish
#gd scottish gaelic
#sk slovak
#sl slovenian
#es spanish
#sv swedish
#cy welsh
#bar bavarian
#br breton
#ca catalan
#nds low saxon
#frr north frislan
#nap neapolitan
#sc sardinian
#eu basque
#co corsican
#gl galician


#inputfile format classified:
#Term	numMatches	Countries	Weights
#here, we need to check how many have been classified correctly
#thus output: Term numMatches Countries Country_Weights classifications cl_weights fit[0/1]

#unclassified
#Term	numprefix	numinfix	numsuffix	numcomplete	numnames	occurences	type_predictability	main_type	av_length	av_locality	mp_locality	class	occperc	vipperc	midPointLat	midPointLon
#here, we just classify, thus output: Term classifications cl_weights

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--infile")
parser.add_argument("-m", "--model")#path to fasttext model
parser.add_argument("-c","--classify") #0 if only check, 1 if to be classified
parser.add_argument("-o", "--outfile")
args = parser.parse_args()

inputfile = ""
if args.infile:
    inputfile = args.infile
else:
    print("no inputfile given!\n")
    exit

modelfile = ""
if args.model:
    modelfile = args.model
else:
    print("no model given!\n")
    exit


doclassify = 0
if args.classify:
    doclassify = int(args.classify)
if doclassify < 0 and doclassify > 1:
    print("classification option is not valid! Set to 0.\n")
outputfile = ""
if args.outfile:
    outputfile = args.outfile
else:
    outputfile = inputfile+"sorted.tsv"


d = dict()
d['fr'] = "france_belgium_switzerland_luxembourg"
d['en'] = "greatbritain_ireland-and-northern-ireland"
d['de'] = "germany_austria_switzerland"
d['bg'] = "bulgaria"
d['cs'] = "czech-republic"
d['da'] = "denmark"
d['nl'] = "netherlands_belgium"
d['et'] = "estonia"
d['fi'] = "finland"
d['el'] = "greece"
d['hu'] = "hungary"
d['is'] = "iceland"
d['ga'] = "ireland-and-northern-ireland"
d['it'] = "italy"
d['lt'] = "lithuania"
d['lb'] = "luxembourg"
d['nn'] = "norway"
d['no'] = "norway"
d['pfl'] = "germany" # palatinate german
d['pl'] = "poland"
d['pt'] = "portugal"
d['ro'] = "romania"
d['sco'] = "greatbritain"
d['gd'] = "greatbritain" #scottish gaelic
d['sk'] = "slovakia"
d['sl'] = "slovenia"
d['es'] = "spain"
d['sv'] = "sweden"
d['cy'] = "greatbritain" # welsh
d['bar'] = "germany_austria" # bavarian
d['br'] = "france" #breton
d['ca'] = "spain" # catalan
d['nds'] = "germany" # low saxon
d['frr'] = "germany_netherlands" # north frislan
d['nap'] = "italy" # neapolitan
d['sc'] = "italy" # sardinian
d['eu'] = "france_spain" # basque
d['co'] = "france" # corsican
d['gl'] = "poland" # galician



    
f = open(outputfile, 'w')

header1 = "Term\tnumMatches\tClass_Countries\tClass_Weights\n"
header2 = "Term\tnumMatches\tCountries\tWeights\tClass_Countries\tClass_Weights\tFit\n"

if doclassify == 0:
    f.write(header2)
else:
    f.write(header1)

model = fasttext.load_model(modelfile)


termfile = pd.read_csv(inputfile,sep='\t',header=0)
terms = termfile['Term'].values
countries = []
matches = []
streetweights = []
fitsum = 0
fitminus = 0
totsum = 0
if doclassify == 0:
    countries = termfile['Countries'].values
    matches = termfile['numMatches'].values
    streetweights = termfile['Weights'].values

for i in range(len(terms)):
    curterm = str(terms[i])
    totsum+=1
    (labels,weights) = model.predict(curterm,k=3)
    #possible output
    #(('__label__en', '__label__fr', '__label__ru'), array([0.85839343, 0.02784043, 0.01825429]))
    countrylist = []
    weightlist = []
    for l in range(len(labels)):
        curlab = labels[l]
        curwt = weights[l]
        countrylab = curlab[9:]
        country = ""
        if countrylab in d:
            country = d[countrylab]
            countrylist.append(str(country))
            weightlist.append(str(curwt))
    countrystr = "_".join(countrylist)
    weightstr = "_".join(weightlist)
    if doclassify == 1:
        tmplist = countrystr.split('_')
        nummatchs = len(set(tmplist))
        if len(countrylist) == 0:
            nummatchs = 0
            fitminus=+1
        outstr = curterm+"\t"+str(nummatchs)+"\t"+countrystr+"\t"+weightstr+"\n"
        f.write(outstr)
    else:
        curcountries = countries[i]
        cc = curcountries.split('_')
        sc = countrystr.split('_')
        numis = len(list(set(cc) & set(sc))) #check if at least one country appears in both classifications
        fit = 0
        if numis > 0:
            fit = numis
            fitsum+=1
        if len(countrylist) == 0:
            fit = -1
            fitminus+=1
        outstr2 = curterm+"\t"+str(matches[i])+"\t"+curcountries+"\t"+str(streetweights[i])+"\t"+countrystr+"\t"+weightstr+"\t"+str(fit)+"\n"
        f.write(outstr2)

if doclassify == 1:
    print("Total number of terms:", totsum)
    print("Number of terms that do not give a result:", fitminus)
else:
    print("Total number of terms:", totsum)
    print("Number of correctly classified terms:", fitsum)
    print("Number of terms that do not give a result:", fitminus)
    print("Percentage of correctly classified terms:", fitsum/totsum)
    print("Percentage of terms without a result:",fitminus/totsum)
