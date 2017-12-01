workflow Manta{
    File LIST
    Array[Array[String]] FAMS=read_tsv(LIST)
    String MANTASCRIPT
    String REFFASTA
    scatter(FAM in FAMS){
        call RunManta {input: MantaScript=MANTASCRIPT,Fa=FAM[1],Mo=FAM[2],P1=FAM[3],RefFasta=REFFASTA}        
    }
}
task RunManta{
    String MantaScript
    String Fa
    String Mo
    String P1
    String RefFasta
    command{
        source deactivate cacila
        ${MantaScript} -b ${Fa},${Mo},${P1} -r ${RefFasta}
    }
  runtime {
    memory: "10 GB"
    cpu: "4"
    queue: "big"
    sla: "-sla miket_sc"
  }   
}