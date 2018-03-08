workflow GenotypeGVCFs{
    File GATK
    File RefFasta
    File RefIndex
    File RefDict
    String sampleName
    Array[File] GVCFs
    File ChrList
    Array[String] Chrs =read_lines(ChrList)
    scatter(Chr in Chrs){
        call runGVCF{input: gatk=GATK, reffasta=RefFasta,refindex=RefIndex,refdict=RefDict,
        samplename=sampleName,gvcfs=GVCFs,chr=Chr}
    }
    call CatVariants{input: gatk=GATK, reffasta=RefFasta,refindex=RefIndex,refdict=RefDict,
    samplename=sampleName,vcfs=runGVCF.rawVCF,vcfidx=runGVCF.rawIndex}
    output{
        File rawVCF=CatVariants.VCF
        File rawIndex=CatVariants.IDX
    }
}
task runGVCF{
    File gatk
    File reffasta
    File refindex
    File refdict
    String samplename
    Array[String] gvcfs
    String chr
    command{
        java -jar ${gatk} \
            -T GenotypeGVCFs \
            -L ${chr}\
            -R ${reffasta} \
            -V ${sep=" -V " gvcfs} \
            -o ${samplename}_rawVariants_${chr}.vcf
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue:"big"
        sla:"-sla miket_sc"
    }
    output {
        File rawVCF = "${samplename}_rawVariants_${chr}.vcf"
        File rawIndex = "${samplename}_rawVariants_${chr}.vcf.idx"
    }
}
task CatVariants{
    File gatk
    File reffasta
    File refindex
    File refdict
    Array[File] vcfs
    Array[File] vcfidx
    String samplename
    command{
    java -Xmx8000m -cp ${gatk} org.broadinstitute.gatk.tools.CatVariants\
        -R ${reffasta} \
        -V ${sep=" -V " vcfs} \
        -out ${samplename}.vcf \
        -assumeSorted
    }
    output{
        File VCF="${samplename}.vcf"
        File IDX="${samplename}.vcf.idx"
    }
    runtime {
        memory: "10 GB"
        cpu: "1"
        queue:"big"
        sla:"-sla miket_sc"
    }
}