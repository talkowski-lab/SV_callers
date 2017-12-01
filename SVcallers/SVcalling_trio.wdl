import "/data/talkowski/hw878/Standard_workflow/SVcallers/Wham/Wham_trio.wdl" as Wham
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Delly/Delly_trio.wdl" as Delly
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Manta/Manta_trio.wdl" as Manta
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Cnvnator/Cnvnator_trio.wdl" as Cnvnator
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Bincov-cnmops/Bincov_trio.wdl" as Bincov
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Collectpesr/collect_trio.wdl" as collect
import "/data/talkowski/hw878/Standard_workflow/QC/Picard/Picard_trio.wdl" as Picard
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Melt/Melt_hg38_trio.wdl" as Melt
import "/data/talkowski/hw878/Standard_workflow/SVcallers/Lumpy/Lumpy_trio.wdl" as Lumpy

workflow SV{
    String reffasta
    File list
    File chrlist
    File blacklist
    File pre_melt
    File cnvnatorscript
    String mantascript
    File refindex
    File lumpy_script
    call Wham.Wham{input: REFFASTA=reffasta,LIST=list,CHRLIST=chrlist}
    call Delly.Delly{input: FASTA=reffasta,LIST=list,BLACK=blacklist}
    call Manta.Manta{input:REFFASTA=reffasta,LIST=list,MANTASCRIPT=mantascript}
    call Cnvnator.Cnvnator{input:Cnvnator=cnvnatorscript,LIST=list}
    call Bincov.Bincov{input:Filelist=list,CHRLIST=chrlist}
    call collect.Collectpesr_trio{input:LIST=list,Chrlist=chrlist}
    call Picard.WGSmetrics{input:LIST=list,REFFASTA=reffasta,Pre_melt=pre_melt}
    call Melt.MELT{input:MELT=melt,Famlist=WGSmetrics.FAM,FASTA=reffasta,FASTAINDEX=refindex}
    call Lumpy.Lumpy{input:LIST=list,lumpyscript=lumpy_script,refFasta=reffasta}
}