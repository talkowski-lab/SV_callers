workflow Cnvnator{
    File LIST
    String cnvnator
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(Fam in FAMS){
        call RunCNVnator as RunCNVnatorp1{input: CNVnatorscript=cnvnator,BamFile=Fam[1]}
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
        File output = "${SampleName}.cnvnator"
    }
  runtime {
    memory: "8 GB"
    cpu: "1"
    queue: "big"
    sla: "-sla miket_sc"
  }   
}
