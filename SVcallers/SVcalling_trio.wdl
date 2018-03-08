import "/data/talkowski/hw878/Standard_workflow/SVcallers/Wham/Wham_trio.wdl" as Wham
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Delly/Delly_trio.wdl" as Delly
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Manta/Manta_trio.wdl" as Manta
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Cnvnator/Cnvnator_trio.wdl" as Cnvnator
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Bincov-cnmops/Bincov_trio.wdl" as Bincov
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Collectpesr/collect_trio.wdl" as collect
import "/data/talkowski/hw878/Standard_workflow/QC/Picard/Picard_trio.wdl" as Picard
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Melt/Melt_hg37_trio.wdl" as Melt
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Lumpy/Lumpy_trio.wdl" as Lumpy
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Cnmops/cnmops.wdl" as Cnmops

workflow SV{
    String reffasta
    File list
    File chrlist
    File blacklist
    File pre_melt
    File cnvnatorscript
    File convertscript
    String mantascript
    File refindex
    File lumpy_script
    File genmatrixPyscript
    File sexpedfile
    String melt
    File autosome
    File allosome
    String refdir
    call Wham.Wham{input: REFFASTA=reffasta,LIST=list,CHRLIST=chrlist}
    call Delly.Delly{input: FASTA=reffasta,LIST=list,BLACK=blacklist}
    call Manta.Manta{input:REFFASTA=reffasta,LIST=list,MANTASCRIPT=mantascript}
    call Cnvnator.Cnvnator{input:Cnvnator=cnvnatorscript,CONVERT=convertscript,LIST=list,REFDIR=refdir}
    call Bincov.Bincov{input:Filelist=list,CHRLIST=chrlist}
    call collect.Collectpesr{input:LIST=list,Chrlist=chrlist}
    call Picard.WGSmetrics{input:LIST=list,REFFASTA=reffasta,Pre_melt=pre_melt}
    call Melt.MELT{input:MELT=melt,Famlist=WGSmetrics.FAM,FASTA=reffasta,FASTAINDEX=refindex}
    call Lumpy.Lumpy{input:LIST=list,lumpyscript=lumpy_script,refFasta=reffasta,BLACK=blacklist}
    call Cnmops.cnmops{input:DIR=Bincov.DIR,Pedfile=sexpedfile,samplepy=genmatrixPyscript,Chromfile=autosome,Allofile=allosome}
}