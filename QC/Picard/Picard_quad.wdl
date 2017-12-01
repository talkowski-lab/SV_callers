workflow WGSmetrics{
    File LIST
    Array[Array[String]] FAMS=read_tsv(LIST)
    String REFFASTA
    scatter(FAM in FAMS){
        call WGSpicard as WGSfa {input: Bamfile=FAM[1],RefFasta=REFFASTA}
        call WGSpicard as WGSmo {input: Bamfile=FAM[2],RefFasta=REFFASTA}
        call WGSpicard as WGSp1 {input: Bamfile=FAM[3],RefFasta=REFFASTA}
        call WGSpicard as WGSs1 {input: Bamfile=FAM[4],RefFasta=REFFASTA}
    }
}
task WGSpicard{
    String RefFasta
    String Bamfile
    command{
        java -Xmx8000m -jar /PHShome/hw878/Software/Picard/picard.jar CollectWgsMetrics \
            I=${Bamfile} \
            O=$(basename ${Bamfile} .bam).wgs \
            VALIDATION_STRINGENCY=LENIENT\
            R=${RefFasta} 
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue: "big"
        sla: "-sla miket_sc"
    } 
}