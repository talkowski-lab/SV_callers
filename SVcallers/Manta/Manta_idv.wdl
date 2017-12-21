workflow Manta{
    File LIST
    Array[Array[String]] FAMS=read_tsv(LIST)
    String MANTASCRIPT
    String REFFASTA
    scatter(FAM in FAMS){
        call RunManta {input: MantaScript=MANTASCRIPT,RefFasta=REFFASTA,Sample=FAM[1],Fam=FAM[0]}
    }
    call gatherfile{input:files=RunManta.mantaout,indexes=RunManta.index}
}
task RunManta{
    String MantaScript
    String Fam
    String Sample
    String RefFasta
    command{
        ${MantaScript} -b ${Sample} -r ${RefFasta}
        cp results/variants/diploidSV.vcf.gz manta.${Fam}.vcf.gz
        cp results/variants/diploidSV.vcf.gz.tbi manta.${Fam}.vcf.gz.tbi
        
    }
    output{
        File mantaout="manta.${Fam}.vcf.gz"
        File index = "manta.${Fam}.vcf.gz.tbi"
    }
  runtime {
    memory: "10 GB"
    cpu: "4"
    queue: "big"
    sla: "-sla miket_sc"
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