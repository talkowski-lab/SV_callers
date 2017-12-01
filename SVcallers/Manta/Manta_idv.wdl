workflow Manta{
    File LIST
    Array[Array[String]] FAMS=read_tsv(LIST)
    String MANTASCRIPT
    String REFFASTA
    scatter(FAM in FAMS){
        call RunManta {input: MantaScript=MANTASCRIPT,RefFasta=REFFASTA,Sample=FAM[1]}
    }
}
task RunManta{
    String MantaScript
    String Sample
    String RefFasta
    command{
        source deactivate cacila
        ${MantaScript} -b ${Sample} -r ${RefFasta}
    }
  runtime {
    memory: "10 GB"
    cpu: "4"
    queue: "big"
    sla: "-sla miket_sc"
  }   
}