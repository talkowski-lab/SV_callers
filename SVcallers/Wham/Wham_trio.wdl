workflow Wham{
    File LIST
    File CHRLIST
    Array[String] CHRS=read_lines(CHRLIST)
    Array[Array[String]] FAMS=read_tsv(LIST)
    String REFFASTA
    scatter(FAM in FAMS){
        call RunWham {input: chrlist=CHRS,Fa=FAM[1],Mo=FAM[2],P1=FAM[3],RefFasta=REFFASTA,fam=FAM[0]}
        call fixwham {input: VCF=RunWham.VCF,fam=FAM[0]}
    }
    call gatherfile{input:files=fixwham.result,index=fixwham.index}
    
}
task RunWham{
    String fam
    Array[String] chrlist
    String Fa
    String Mo
    String P1
    String RefFasta
    command{
        whamg -c ${sep="," chrlist} -a ${RefFasta} -f ${Fa},${Mo},${P1} > ${fam}.wham.vcf
    }
    output{
        File VCF="${fam}.wham.vcf"
    }
  runtime {
    memory: "15 GB"
    cpu: "4"
    queue: "big"
    sla: "-sla miket_sc"
  }   
}
task fixwham{
    String fam
    File VCF
    command{
        sed 's/01 /01_/g' ${VCF}|sed 's/02 /02_/g'|sed 's/03 /03_/g' |vcf-sort -c |bgzip -c > wham.${fam}.vcf.gz
        tabix -p vcf wham.${fam}.vcf.gz
    }
    output{
        File result="wham.${fam}.vcf.gz"
        File index="wham.${fam}.vcf.gz.tbi"
    }
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}
task gatherfile{
    Array[File] files
    Array[File] index
    command <<<
        mkdir results
        cp {${sep="," files}} {${sep="," index}} results
    >>>
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}