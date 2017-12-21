workflow Cnvnator{
    File LIST
    String Cnvnator
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(Fam in FAMS){
        call RunCNVnator as RunCNVnatorp1{input: CNVnatorscript=Cnvnator,BamFile=Fam[1]}
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
