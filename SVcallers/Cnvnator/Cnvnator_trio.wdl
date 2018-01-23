workflow Cnvnator{
    File LIST
    String Cnvnator
    String CONVERT
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(Fam in FAMS){
        call RunCNVnator as RunCNVnatorfa{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[1]}
        call RunCNVnator as RunCNVnatormo{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[2]}
        call RunCNVnator as RunCNVnatorp1{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[3]}
        }
    call gatherfile{input: DELfa=RunCNVnatorfa.DEL,DELmo=RunCNVnatormo.DEL,DELp1=RunCNVnatorp1.DEL,DUPfa=RunCNVnatorfa.DUP,DUPmo=RunCNVnatormo.DUP,DUPp1=RunCNVnatorp1.DUP}
}
task RunCNVnator{
    String CNVnatorscript
    String BamFile
    String convert
    String SampleName= basename(BamFile, ".bam") 
    command{
        ${CNVnatorscript} -b ${BamFile} -o ${SampleName}.cnvnator
        python ${convert} ${SampleName}.cnvnator ${SampleName}
    }
    output {
        File DEL = "${SampleName}.cnvnator.DEL.bed"
        File DUP = "${SampleName}.cnvnator.DUP.bed"
    }
  runtime {
    memory: "8 GB"
    cpu: "6"
    queue: "big"
    sla: "-sla miket_sc"
  }   
}
task gatherfile{
    Array[File] DELfa
    Array[File] DELmo
    Array[File] DELp1
    Array[File] DUPfa
    Array[File] DUPmo
    Array[File] DUPp1
    command <<<
        mkdir results
        cp {${sep="," DELfa}} results
        cp {${sep="," DELmo}} results
        cp {${sep="," DELp1}} results
        cp {${sep="," DUPfa}} results
        cp {${sep="," DUPmo}} results
        cp {${sep="," DUPp1}} results
    >>>
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}
