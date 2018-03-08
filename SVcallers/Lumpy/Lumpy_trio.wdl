workflow Lumpy {
    File LIST
    Array[Array[String]] FAMS=read_tsv(LIST)
    File lumpyscript
    # File cnvnatorscript
    # File mantascript
    String refFasta
    String BLACK
    # File refIndex
    scatter(FAM in FAMS){
        call Get_pesr as Get_pesr_Fa{input: BamFile=FAM[1], Fam=FAM[0]} 
        call Get_pesr as Get_pesr_Mo{input: BamFile=FAM[2], Fam=FAM[0]} 
        call Get_pesr as Get_pesr_P1{input: BamFile=FAM[3], Fam=FAM[0]} 
        call RunLumpy{input:SampleName=FAM[0], LumpyScript=lumpyscript,
            PeBam=[Get_pesr_Fa.PE,Get_pesr_Mo.PE,Get_pesr_P1.PE],
            PeBamIdx=[Get_pesr_Fa.PEidx,Get_pesr_Mo.PEidx,Get_pesr_P1.PEidx],
            SrBam=[Get_pesr_Fa.SR,Get_pesr_Mo.SR,Get_pesr_P1.SR],
            SrBamIdx=[Get_pesr_Fa.SRidx,Get_pesr_Mo.SRidx,Get_pesr_P1.SRidx],
            Bam=[Get_pesr_Fa.BAM,Get_pesr_Mo.BAM,Get_pesr_P1.BAM] ,black=BLACK}
    }
    call gatherfile{input:files=RunLumpy.LumpyCall,indexes=RunLumpy.Index}
}

task Get_pesr{
    String BamFile
    String SampleName= basename(BamFile, ".bam")
    String Fam
    command {
        SampleName=`basename ${BamFile} .bam`
        sambamba sort -t 8 --tmpdir `pwd`/tmp -n ${BamFile} -o /dev/stdout | sambamba view -h /dev/stdin -o /dev/stdout |\
        samblaster -M -a -e -d ${SampleName}.disc.sam -s ${SampleName}.split.sam -o /dev/null 
        
        sambamba view -h --sam-input -t 8 -f bam -l 0 ${SampleName}.disc.sam -o /dev/stdout |\
        sambamba sort -t 8 --tmpdir `pwd`/tmp /dev/stdin -o ${SampleName}.discordants.bam
        
        sambamba view -h --sam-input -t 8 -f bam -l 0 ${SampleName}.split.sam -o/dev/stdout |\
        sambamba sort -t 8 --tmpdir `pwd`/tmp /dev/stdin -o ${SampleName}.splitters.bam
        if [ -s ${SampleName}.discordants.bam ]
            then
                rm -f ${SampleName}.disc.sam
            else
                exit 1
            fi      
        if [ -s ${SampleName}.splitters.bam ]
            then
                rm -f ${SampleName}.split.sam
            else
                exit 1
            fi                 
    }
    output {
        File PE = "${SampleName}.discordants.bam"
        File SR = "${SampleName}.splitters.bam"
        String BAM = "${BamFile}"
        File PEidx = "${SampleName}.discordants.bam.bai"
        File SRidx = "${SampleName}.splitters.bam.bai"
    }
  runtime {
    sla: "-sla miket_sc"
    queue: "big"
    memory: "10 GB"
    cpu: "4"
  }   
    
}
task RunLumpy{
    File LumpyScript
    String black
    Array[File] PeBam
    Array[File] SrBam
    Array[File] Bam
    Array[File] PeBamIdx
    Array[File] SrBamIdx
    String SampleName
    command{
        module load svtyper
        module load anaconda/4.0.5
        bash ${LumpyScript} -z ${black} -b ${sep="," Bam} -p ${sep="," PeBam} -s ${sep="," SrBam} -o ${SampleName}
        vcf-sort ${SampleName}.vcf |bgzip -c > lumpy.${SampleName}.vcf.gz
        tabix lumpy.${SampleName}.vcf.gz
    }
    output {
        File LumpyCall = "lumpy.${SampleName}.vcf.gz"
        File Index = "lumpy.${SampleName}.vcf.gz.tbi"
    }
  runtime {
    sla: "-sla miket_sc"
    queue: "big"
    memory: "10 GB"
    cpu: "4"
  }   
}
task gatherfile{
    Array[File] files
    Array[File] indexes
    command <<<
        mkdir results
        cp {${sep="," files}} results
        cp {${sep="," indexes}} results
    >>>
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}