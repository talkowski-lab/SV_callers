workflow Cnvnator{
    File LIST
    String cnvnator
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(Fam in FAMS){
        call RunCNVnator as RunCNVnatorfa{input: CNVnatorscript=cnvnator,BamFile=Fam[1]}
        call RunCNVnator as RunCNVnatormo{input: CNVnatorscript=cnvnator,BamFile=Fam[2]}
        call RunCNVnator as RunCNVnatorp1{input: CNVnatorscript=cnvnator,BamFile=Fam[3]}
        call RunCNVnator as RunCNVnators1{input: CNVnatorscript=cnvnator,BamFile=Fam[4]}
        }

}
task RunCNVnator{
    String CNVnatorscript
    String BamFile
    String SampleName= basename(BamFile, ".bam") 
    command{
        ${CNVnatorscript} -b ${BamFile} -o ${SampleName}.cnvnator
    }
    output {
        File out = "${SampleName}.cnvnator"
    }
  runtime {
    memory: "8 GB"
    cpu: "1"
    queue: "big"
    sla: "-sla miket_sc"
  }   
}
