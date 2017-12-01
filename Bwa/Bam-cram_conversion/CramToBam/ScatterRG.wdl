# This scatters by chr
workflow work{
    File BamFile
    File BamIndex
    File RGfile
    Array[String] RGs = read_lines(RGfile)
    String sampleName
    String RefFasta
    scatter(RG in RGs){
        call EchoString{input: InputString=RG,
        bamfile=BamFile,
        bamindex=BamIndex,
        SampleName=sampleName, 
        refFasta=RefFasta
        }
    }
    call GatherString{input: OutputStrings=EchoString.result, SampleName=sampleName}
    output{
        File BAM=GatherString.BAM
        File BAI=GatherString.BAI
    }
}
task EchoString{
    String InputString
    # Array[Array[String]] Elements = read_tsv(InputString)
    File bamfile
    File bamindex
    String SampleName
    String refFasta
    command{
            module list
            samtools view -h -r "$(echo "${InputString}"|cut -f 2|sed 's/^ID://g')" ${bamfile} |\
            samtools sort -n -@ 4 - |samtools bam2fq -F 2304 - | bwa mem -M -R "$(echo "${InputString}" |sed 's/\t/\\t/g')" -t 4 -C -p ${refFasta} - |\
            samblaster -M|\
            sambamba view --sam-input -t 4 -f bam -l 0 /dev/stdin -o /dev/stdout |\
            sambamba sort --tmpdir `pwd`/tmp -t 4 /dev/stdin -o ${SampleName}_sorted_reads.bam
    }
    output {
        File result="${SampleName}_sorted_reads.bam"
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue: "big"
        sla: "-sla miket_sc"
    }
}
task GatherString{
    String SampleName
    Array[File] OutputStrings
    command{
            samtools merge -@ 4 ${SampleName}.bam ${sep=" " OutputStrings}
            sambamba index -t 4 ${SampleName}.bam
    }
    output{
        File BAM="${SampleName}.bam"
        File BAI="${SampleName}.bam.bai"
    }
    runtime {
        continueOnReturnCode: true
        memory: "8 GB"
        cpu: "1"
        queue: "big"
        sla: "-sla miket_sc"
    }
}