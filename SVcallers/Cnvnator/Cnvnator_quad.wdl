workflow Cnvnator{
    File LIST
    String Cnvnator
    String CONVERT
    String REFDIR
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(Fam in FAMS){
        call RunCNVnator as RunCNVnatorfa{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[1],refdir=REFDIR}
        call RunCNVnator as RunCNVnatormo{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[2],refdir=REFDIR}
        call RunCNVnator as RunCNVnatorp1{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[3],refdir=REFDIR}
        call RunCNVnator as RunCNVnators1{input: CNVnatorscript=Cnvnator,convert=CONVERT,BamFile=Fam[4],refdir=REFDIR}
        }
    call gatherfile{input: DELfa=RunCNVnatorfa.DEL,DELmo=RunCNVnatormo.DEL,DELp1=RunCNVnatorp1.DEL,DELs1=RunCNVnators1.DEL,DUPfa=RunCNVnatorfa.DUP,DUPmo=RunCNVnatormo.DUP,DUPp1=RunCNVnatorp1.DUP,DUPs1=RunCNVnators1.DUP}
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
    cpu: "6"
    queue: "big"
    sla: ""
  }   
}
task gatherfile{
    Array[File] DELfa
    Array[File] DELmo
    Array[File] DELp1
    Array[File] DELs1
    Array[File] DUPfa
    Array[File] DUPmo
    Array[File] DUPp1
    Array[File] DUPs1
    command <<<
        mkdir results
        cp {${sep="," DELfa}} results
        cp {${sep="," DELmo}} results
        cp {${sep="," DELp1}} results
        cp {${sep="," DELs1}} results
        cp {${sep="," DUPfa}} results
        cp {${sep="," DUPmo}} results
        cp {${sep="," DUPp1}} results
        cp {${sep="," DUPs1}} results
    >>>
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}
