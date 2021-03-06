import "/data/talkowski/hw878/Standard_workflow/SVcallers/Wham/Wham_quad.wdl" as Wham
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Delly/Delly_quad.wdl" as Delly
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Manta/Manta_quad.wdl" as Manta
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Cnvnator/Cnvnator_quad.wdl" as Cnvnator
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Bincov-cnmops/Bincov_quad.wdl" as Bincov
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Collectpesr/collect_quad.wdl" as collect
import "/data/talkowski/hw878/Standard_workflow/QC/Picard/Picard_quad.wdl" as Picard
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Melt/Melt_hg38_quad.wdl" as Melt
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Lumpy/Lumpy_quad.wdl" as Lumpy
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
    String refdir
    String melt
    File autosome
    File allosome
    # call Wham.Wham{input: REFFASTA=reffasta,LIST=list,CHRLIST=chrlist}
    # call Delly.Delly{input: FASTA=reffasta,LIST=list,BLACK=blacklist}
    # call Manta.Manta{input:REFFASTA=reffasta,LIST=list,MANTASCRIPT=mantascript}
    # call Cnvnator.Cnvnator{input:Cnvnator=cnvnatorscript,CONVERT=convertscript,LIST=list,REFDIR=refdir}
    # call Bincov.Bincov{input:Filelist=list,CHRLIST=chrlist}
    # call collect.Collectpesr{input:LIST=list,Chrlist=chrlist}
    # call Picard.WGSmetrics{input:LIST=list,REFFASTA=reffasta,Pre_melt=pre_melt}
    # call Melt.MELT{input:MELT=melt,Famlist=WGSmetrics.FAM,FASTA=reffasta,FASTAINDEX=refindex}
    call Lumpy.Lumpy{input:LIST=list,lumpyscript=lumpy_script,refFasta=reffasta,BLACK=blacklist}
    # call Cnmops.cnmops{input:DIR=Bincov.DIR,Pedfile=sexpedfile,samplepy=genmatrixPyscript,Chromfile=autosome,Allofile=allosome}
}