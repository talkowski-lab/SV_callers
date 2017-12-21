workflow Delly{
    File LIST
    String FASTA
    String BLACK
    Array[Array[String]] FAMS=read_tsv(LIST)
    scatter(FAM in FAMS){
        call doDelly as doDellyDEL{input: Type="DEL",P1=FAM[1],Fasta=FASTA,Black=BLACK}
        call doDelly as doDellyDUP{input: Type="DUP",P1=FAM[1],Fasta=FASTA,Black=BLACK}
        call doDelly as doDellyINV{input: Type="INV",P1=FAM[1],Fasta=FASTA,Black=BLACK}
        # call doDelly as doDellyTRA{input: Type="TRA",Fam=FAM[0],Fa=FAM[1],Mo=FAM[2],P1=FAM[3],Fasta=FASTA,Black=BLACK} segfault issues
        call gatherfile{input: Fam=FAM[0],DELBCF=doDellyDEL.BCF,DELCSI=doDellyDEL.CSI,
                      DUPBCF=doDellyDUP.BCF,DUPCSI=doDellyDUP.CSI,
                      INVBCF=doDellyINV.BCF,INVCSI=doDellyINV.CSI
            }
        }
    call gather{input:files=gatherfile.Result,indexes=gatherfile.Index}
}
task doDelly{
    String P1
    String Type
    String Fam
    String Black
    String Fasta
    command{
        export OMP_NUM_THREADS=2 
        /data/talkowski/hw878/Prenatal/Delly/delly_v0.7.3_parallel_linux_x86_64bit call -t ${Type} -o ${Fam}.${Type}.bcf \
        -x ${Black}  -q 20 -n -g ${Fasta} \
        ${P1} 
    }
    output{
        File BCF="${Fam}.${Type}.bcf"
        File CSI="${Fam}.${Type}.bcf.csi"
    }
    runtime{
        cpu: "2"
        memory: "8 GB"
        queue: "big"
        sla: "-sla miket_sc"
    }
}
task gatherfile{
    String Fam
    File DELBCF
    File DELCSI
    File DUPBCF
    File DUPCSI
    File INVBCF
    File INVCSI
    command {
        bcftools view ${DELBCF} |grep "#" > header.txt
        bcftools view ${DELBCF} |grep -v "#" > del.vcf
        bcftools view ${DUPBCF} |grep -v "#"> dup.vcf
        bcftools view ${INVBCF} |grep -v "#"> inv.vcf
        cat header.txt del.vcf dup.vcf inv.vcf tra.vcf | vcf-sort -c | bgzip -c > delly.${Fam}.vcf.gz
        tabix delly.${Fam}.vcf.gz
    }
    output{
        File Result="delly.${Fam}.vcf.gz"
        File Index="delly.${Fam}.vcf.gz.tbi"
    }
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}
task gather{
    Array[File] files
    Array[File] indexes
    command <<<
        mkdir results
        cp {${sep="," files},} results
        cp {${sep="," indexes},} results
    >>>
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
}