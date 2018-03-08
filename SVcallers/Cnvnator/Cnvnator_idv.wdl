workflow Cnvnator{
    File LIST
    String Cnvnator
    String CONVERT
    String REFDIR
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(Fam in FAMS){
        call RunCNVnator as RunCNVnatorp1{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[2],refdir=REFDIR}
        }
    call gatherfile{input: DELp1=RunCNVnatorp1.DEL,DUPp1=RunCNVnatorp1.DUP}
}
task RunCNVnator{
    String CNVnatorscript
    String BamFile
    String convert
    String refdir
    String SampleName= basename(BamFile, ".bam") 
    command{
        ${CNVnatorscript} -b ${BamFile} -o ${SampleName}.cnvnator -r ${refdir}
        python ${convert} ${SampleName}.cnvnator ${SampleName}
    }
    output {
        File DEL = "${SampleName}.cnvnator.DEL.bed"
        File DUP = "${SampleName}.cnvnator.DUP.bed"
    }
  runtime {
    memory: "8 GB"
    cpu: "4"
    queue: "big"
    sla: "-sla miket_sc"
  }   
}
task gatherfile{
    Array[File] DELp1
    Array[File] DUPp1
    command <<<
        mkdir results
        cp {${sep="," DELp1}} results
        cp {${sep="," DUPp1}} results
    >>>
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}
