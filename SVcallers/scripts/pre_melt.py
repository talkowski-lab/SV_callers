import sys
[_,famfile,picarddir]=sys.argv

def getmed(file):
    i=0
    with open(file,'r') as f:
        for line in f:
            i+=1
            if i == 8:
                return line.split('\t')[3]

with open(famfile,'r') as f:
    for line in f:
        dat=line.rstrip().split('\t')
        nsample=len(dat)
        for i in range(1,nsample):
            # print(dat[i])
            ID=dat[i].split('/')[-1][0:-4]
            # print(ID)
            picardfile=picarddir+'/'+ID+'.wgs'
            dat.append(getmed(picardfile))
        print('\t'.join(dat))
        # fa=dat[1].split('/')[-1].split('.')[0]
        # fa=dat[1].split('/')[-1].split('.')[0]
        # fa=dat[1].split('/')[-1].split('.')[0]