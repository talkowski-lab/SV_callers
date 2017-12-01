workflow Collect_bam{
    File BAMFILE
    File CHRLIST
    Array[Array[String]] CHRS=read_tsv(CHRLIST)
    scatter(CHR in CHRS){
        call svcollect_bam{input:bam=BAMFILE,chr=CHR[0]}
    }
    call merge_bam as merge_PE{input: bam =BAMFILE,results=svcollect_bam.PE,tag="PE"}
    call merge_bam as merge_SR{input: bam =BAMFILE,results=svcollect_bam.SR,tag="SR"}
    output{
        File PE=merge_PE.Matrix
        File SR=merge_SR.Matrix
    }
}
task svcollect_bam{
    String bam
    String chr
    String SampleName= basename(bam, ".bam")
    command<<<
        svtk collect-pesr ${bam} -r ${chr} sample_sr.txt sample_pe.txt
        awk -v OFS="\t" '{print $0,"${SampleName}"}' sample_sr.txt > ${SampleName}_sr_${chr}.txt
        awk -v OFS="\t" '{print $0,"${SampleName}"}' sample_pe.txt > ${SampleName}_pe_${chr}.txt
    >>>
    output{
        File PE="${SampleName}_pe_${chr}.txt"
        File SR="${SampleName}_sr_${chr}.txt"
    }
    runtime {
        memory: "4 GB"
        cpu: "1"
        queue:"short"
        sla:"-sla miket_sc"
    }
}
task merge_bam{
    String tag
    String bam
    String SampleName= basename(bam, ".bam")
    Array[File] results
    command{
        sort -k1,1 -k2,2n -m ${sep=" " results}  > ${SampleName}.${tag}.sorted.txt
    }
    output{
        File Matrix="${SampleName}.${tag}.sorted.txt"
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue:"big"
        sla:"-sla miket_sc"
    }
}