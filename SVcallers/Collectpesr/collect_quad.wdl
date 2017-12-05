import "/data/talkowski/hw878/Standard_workflow/SVcallers/Collectpesr/collect_idv.wdl" as COLLECTBAM
workflow Collectpesr{
    File LIST
    File Chrlist
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(FAM in FAMS){
        call COLLECTBAM.Collect_bam as svcFa{input: BAMFILE=FAM[1],CHRLIST=Chrlist}
        call COLLECTBAM.Collect_bam as svcMo{input: BAMFILE=FAM[2],CHRLIST=Chrlist}
        call COLLECTBAM.Collect_bam as svcP1{input: BAMFILE=FAM[3],CHRLIST=Chrlist}
        call COLLECTBAM.Collect_bam as svcS1{input: BAMFILE=FAM[4],CHRLIST=Chrlist}
    }
    call merge as mergePE{input: tag="PE",Faresults=svcFa.PE,Moresults=svcMo.PE,P1results=svcP1.PE,S1results=svcS1.PE}
    call merge as mergeSR{input: tag="SR",Faresults=svcFa.SR,Moresults=svcMo.SR,P1results=svcP1.SR,S1results=svcS1.SR}
}
# task svcollect{
    # String bam
    # String SampleName= basename(bam, ".bam")
    # command<<<
        # svtk collect-pesr ${bam} sample_sr.txt sample_pe.txt
        # awk -v OFS="\t" '{print $0,${SampleName}}' sample_sr.txt > ${SampleName}_sr.txt
        # awk -v OFS="\t" '{print $0,${SampleName}}' sample_pe.txt > ${SampleName}_pe.txt
    # >>>
    # output{
        # File PE="${SampleName}_pe.txt"
        # File SR="${SampleName}_sr.txt"
    # }
    # runtime {
        # memory: "8 GB"
        # cpu: "1"
        # queue:"medium"
        # sla:"-sla miket_sc"
    # }
# }
task merge{
    String tag
    Array[File] Faresults
    Array[File] Moresults
    Array[File] P1results
    Array[File] S1results
    command{
        sort -k1,1 -k2,2n -m ${sep=" " Faresults} ${sep=" " Moresults} ${sep=" " P1results} ${sep=" " S1results}|bgzip -c > matrics.${tag}.sorted.txt.gz
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

