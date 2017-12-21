import "/data/talkowski/hw878/Standard_workflow/SVcallers/Collectpesr/collect_idv.wdl" as COLLECTBAM
workflow Collectpesr{
    File LIST
    File Chrlist
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(FAM in FAMS){
        call COLLECTBAM.Collect_bam as svcP1{input: BAMFILE=FAM[1],CHRLIST=Chrlist}
    }
    call merge as mergePE{input: tag="PE",P1results=svcP1.PE}
    call merge as mergeSR{input: tag="SR",P1results=svcP1.SR}
}

task merge{
    String tag
    Array[File] P1results
    command{
        sort -k1,1 -k2,2n -m ${sep=" " P1results} |bgzip -c > matrics.${tag}.sorted.txt.gz
        tabix -b 2 -e 2 matrics.${tag}.sorted.txt.gz
    }
    output{
        File Matrix="matrics.${tag}.sorted.txt.gz"
        File Index="matrics.${tag}.sorted.txt.gz.tbi"
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue:"big"
        sla:"-sla miket_sc"
    }
}

