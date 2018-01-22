workflow MELT{
    String MELT # now this is a directory
    File Famlist
    Array[Array[String]] Families=read_tsv(Famlist)
    File FASTA
    File FASTAINDEX
    scatter(Family in Families){
        call Melt{input:Melt=MELT,Fam=Family[0],Bam=Family[1],Fasta=FASTA,FastaIndex=FASTAINDEX,Coverage=Family[2]}
    }
    call gatherfile{input:files=Melt.Result,index=Melt.Index}
}
task Melt{
    String Melt
    String Fam
    String Bam
    File Fasta
    File FastaIndex
    String Coverage
    command{
        mkdir Work
        mkdir Work/me_refs/
        cp ${Melt}/me_refs/1KGP_Hg19/*.zip Work/me_refs/.
        ls Work/me_refs/*.zip >Work/me_refs/mei_list.txt
        java -Xmx8G -jar ${Melt}/MELT.jar Single -bamfile ${Bam} -w . -h ${Fasta} -t Work/me_refs/mei_list.txt -n ${Melt}/add_bed_files/1KGP_Hg19/hg19.genes.bed -c ${Coverage}
        cat SVA.final_comp.vcf |grep "#" > ${Fam}.header.txt
        cat SVA.final_comp.vcf |grep -v "#" > ${Fam}.sva.vcf
        cat LINE1.final_comp.vcf |grep -v "#"> ${Fam}.line1.vcf
        cat ALU.final_comp.vcf |grep -v "#"> ${Fam}.alu.vcf
        cat ${Fam}.header.txt ${Fam}.sva.vcf ${Fam}.line1.vcf ${Fam}.alu.vcf | vcf-sort -c |bgzip -c > melt.${Fam}.vcf.gz
        tabix -p vcf melt.${Fam}.vcf.gz        
    }
    output{
        File Result="melt.${Fam}.vcf.gz"
        File Index="melt.${Fam}.vcf.gz.tbi"
    }
    runtime{
        cpu: "1"
        memory: "9 GB"
        queue: "big"
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