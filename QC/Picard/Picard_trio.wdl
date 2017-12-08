workflow WGSmetrics{
    File LIST
    File Pre_melt
    Array[Array[String]] FAMS=read_tsv(LIST)
    String REFFASTA
    scatter(FAM in FAMS){
        call WGSpicard as WGSfa {input: Bamfile=FAM[1],RefFasta=REFFASTA}
        call WGSpicard as WGSmo {input: Bamfile=FAM[2],RefFasta=REFFASTA}
        call WGSpicard as WGSp1 {input: Bamfile=FAM[3],RefFasta=REFFASTA}
    }
    call genMELTfam{input:pre_melt=Pre_melt,List=LIST,Faresult=WGSfa.result,Moresult=WGSmo.result,P1result=WGSp1.result}
    output{
        File FAM=genMELTfam.MeltFam
    }
}
task WGSpicard{
    String RefFasta
    String Bamfile
    String BamName=basename(Bamfile,".bam")
    command{
        java -Xmx8000m -jar /PHShome/hw878/Software/Picard/picard.jar CollectWgsMetrics \
            I=${Bamfile} \
            O=${BamName}.wgs \
            VALIDATION_STRINGENCY=LENIENT\
            R=${RefFasta} 
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue: "big"
        sla: "-sla miket_sc"
    } 
    output{
        File result="${BamName}.wgs"
    }
}
task genMELTfam{
    File List
    String ListName=basename(List,".fam")
    Array[File] Faresult
    Array[File] Moresult
    Array[File] P1result
    File pre_melt
    command<<<
        mkdir results
        cp {${sep="," Faresult},} results
        cp {${sep="," Moresult},} results
        cp {${sep="," P1result},} results
        python ${pre_melt} ${List} results > ${ListName}_melt.fam
     >>>
    runtime {
        memory: "2 GB"
        cpu: "1"
        queue: "vshort"
        sla: "-sla miket_sc"
    } 
     output{
        File MeltFam="${ListName}_melt.fam"
     }
}