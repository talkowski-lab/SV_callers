import sys
[_,pedfile,chrom,mode,dir]=sys.argv
def printchr(line,chrom,mode,dir):
    dat=line.split('\t')
    sample=dat[1]
    sex = dat[4]
    if mode=="normal" or (mode=="male" and sex=='1') or (mode=="female" and sex=='2'):
#     for c in chrlist:
        print(sample+'\t'+dir+'/'+sample+'_'+str(chrom)+'.bed.gz')
with open(pedfile,'r') as f:
    for line in f:
        printchr(line,chrom,mode,dir)