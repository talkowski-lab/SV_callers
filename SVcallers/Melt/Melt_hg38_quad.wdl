workflow MELT{
    String MELT
    File Famlist
    Array[Array[String]] Families=read_tsv(Famlist)
    File FASTA
    File FASTAINDEX
    scatter(Family in Families){
        call preprocess as Fapre {input: Melt=MELT,BamFile=Family[1],Fasta=FASTA,FastaIndex=FASTAINDEX,Fam=Family[0],Role="fa"}
        call IndivAnalysis as FaIdv{input: Melt=MELT,Bamdir=Fapre.Bamdir,Fam=Family[0],Fasta=FASTA,FastaIndex=FASTAINDEX,Picard=Family[5]}
        call preprocess as Mopre {input: Melt=MELT,BamFile=Family[2],Fasta=FASTA,FastaIndex=FASTAINDEX,Fam=Family[0],Role="mo"}
        call IndivAnalysis as MoIdv{input: Melt=MELT,Bamdir=Mopre.Bamdir,Fam=Family[0],Fasta=FASTA,FastaIndex=FASTAINDEX,Picard=Family[6]}
        call preprocess as P1pre {input: Melt=MELT,BamFile=Family[3],Fasta=FASTA,FastaIndex=FASTAINDEX,Fam=Family[0],Role="p1"}
        call IndivAnalysis as P1Idv{input: Melt=MELT,Bamdir=P1pre.Bamdir,Fam=Family[0],Fasta=FASTA,FastaIndex=FASTAINDEX,Picard=Family[7]}
        call preprocess as S1pre {input: Melt=MELT,BamFile=Family[4],Fasta=FASTA,FastaIndex=FASTAINDEX,Fam=Family[0],Role="s1"}
        call IndivAnalysis as S1Idv{input: Melt=MELT,Bamdir=S1pre.Bamdir,Fam=Family[0],Fasta=FASTA,FastaIndex=FASTAINDEX,Picard=Family[8]}
        
        call genotype as ALUgeno{input: Melt=MELT,Fabam=Fapre.Bamdir,Mobam=Mopre.Bamdir,P1bam=P1pre.Bamdir,S1bam=S1pre.Bamdir,Fam=Family[0],
                                Type="ALU",
                                Fadir=FaIdv.Dir,Modir=MoIdv.Dir,P1dir=P1Idv.Dir,S1dir=S1Idv.Dir,
                                Fasta=FASTA,FastaIndex=FASTAINDEX}
        call genotype as SVAgeno{input: Melt=MELT,Fabam=Fapre.Bamdir,Mobam=Mopre.Bamdir,P1bam=P1pre.Bamdir,S1bam=S1pre.Bamdir,Fam=Family[0],
                                Type="SVA",
                                Fadir=FaIdv.Dir,Modir=MoIdv.Dir,P1dir=P1Idv.Dir,S1dir=S1Idv.Dir,
                                Fasta=FASTA,FastaIndex=FASTAINDEX}
        call genotype as LINE1geno{input: Melt=MELT,Fabam=Fapre.Bamdir,Mobam=Mopre.Bamdir,P1bam=P1pre.Bamdir,S1bam=S1pre.Bamdir,Fam=Family[0],
                                Type="LINE1",
                                Fadir=FaIdv.Dir,Modir=MoIdv.Dir,P1dir=P1Idv.Dir,S1dir=S1Idv.Dir,
                                Fasta=FASTA,FastaIndex=FASTAINDEX}
        call combine{input:SVA=SVAgeno.Meltresult,ALU=ALUgeno.Meltresult,LINE1=LINE1geno.Meltresult,Fam=Family[0],Father=Family[1],Mother=Family[2],Proband=Family[3],Sibling=Family[4]}
    }
    call gatherfile{input:files=combine.Melt,index=combine.Index}
}
task preprocess{
    String Melt
    String Fam
    String Role
    String BamFile
    File Fasta
    File FastaIndex
    command{
        ln ${BamFile} ${Fam}${Role}.bam
        ln ${BamFile}.bai ${Fam}${Role}.bam.bai
        java -jar ${Melt}/MELT.jar Preprocess -bamfile ${Fam}${Role}.bam -h ${Fasta}
        # mv ${Fam}${Role}.bam.disc.bam.bai ${Fam}${Role}.bam.disc.bai
        str=`pwd`/${Fam}${Role}.bam
        echo $str>out.tmp
    }
    output {
        String Bamdir = read_string("out.tmp")
    }
    runtime {
        memory: "10 GB"
        cpu: "1"
        queue: "big"
        sla: "-sla miket_sc"
        sp: "-sp 70"
    }
}

task IndivAnalysis{
    String Melt
    String Fam
    String Bamdir
    File Fasta
    File FastaIndex
    String Picard
    command{
        mkdir Work
        mkdir Work/me_refs/
        cp ${Melt}/me_refs/Hg38/*.zip Work/me_refs/.
        ls Work/me_refs/*.zip >Work/me_refs/mei_list.txt
        java -Xmx6G -jar ${Melt}/MELT.jar IndivAnalysis -c ${Picard} -bamfile ${Bamdir} -w Work -t Work/me_refs/mei_list.txt -h ${Fasta}
        mkdir ALU
        mkdir LINE1
        mkdir SVA
        mv Work/*LINE1* LINE1/.
        mv Work/*ALU* ALU/.
        mv Work/*SVA* SVA/.
        pwd>out.tmp
    }
    runtime {
        memory: "16 GB"
        cpu: "1"
        queue: "big"
        sla: "-sla miket_sc"
        sp: "-sp 80"
    }
    output{
        String Dir=read_string("out.tmp")
    }
}
task genotype{
    String Melt
    String Fabam
    String Mobam
    String P1bam
    String S1bam
    String Fam
    String Type
    String Fadir
    String Modir
    String P1dir
    String S1dir
    File Fasta
    File FastaIndex
    command{
        mkdir ${Type}
        ln ${Fadir}/${Type}/* ${Type}/
        ln ${Modir}/${Type}/* ${Type}/
        ln ${P1dir}/${Type}/* ${Type}/
        java -Xmx2G -jar ${Melt}/MELT.jar GroupAnalysis -discoverydir ${Type} -w ${Type} -t ${Fadir}/Work/me_refs/${Type}_MELT.zip -h ${Fasta} -n ${Melt}/add_bed_files/1KGP_Hg19/hg19.genes.bed     
        java -Xmx2G -jar ${Melt}/MELT.jar Genotype -bamfile ${Fabam} -t ${Fadir}/Work/me_refs/${Type}_MELT.zip -h ${Fasta} -w ${Type} -p ${Type}
        java -Xmx2G -jar ${Melt}/MELT.jar Genotype -bamfile ${Mobam} -t ${Modir}/Work/me_refs/${Type}_MELT.zip -h ${Fasta} -w ${Type} -p ${Type}
        java -Xmx2G -jar ${Melt}/MELT.jar Genotype -bamfile ${P1bam} -t ${P1dir}/Work/me_refs/${Type}_MELT.zip -h ${Fasta} -w ${Type} -p ${Type}
        java -Xmx2G -jar ${Melt}/MELT.jar Genotype -bamfile ${S1bam} -t ${S1dir}/Work/me_refs/${Type}_MELT.zip -h ${Fasta} -w ${Type} -p ${Type}
        ls ${Type}/*.${Type}.tsv > ${Type}/list.txt
        java -Xmx2G -jar ${Melt}/MELT.jar MakeVCF -genotypingdir ${Type} -h ${Fasta} -t ${Fadir}/Work/me_refs/${Type}_MELT.zip -w ${Type} -p ${Type} -o ${Type}
        cp ${Type}/${Type}.final_comp.vcf ${Fam}.${Type}.melt.vcf
    }
    output{
        File Meltresult="${Fam}.${Type}.melt.vcf"
    }
    runtime {
        memory: "16 GB"
        cpu: "1"
        queue: "big"
        sla: "-sla miket_sc"
        sp: "-sp 90"
    }
}
task combine{
    String Fam
    String Father
    String Mother
    String Proband
    String Sibling
    String Fa = basename(Father, ".bam")
    String Mo = basename(Mother, ".bam")
    String P1 = basename(Proband, ".bam")
    String S1 = basename(Sibling, ".bam")
    File ALU
    File SVA
    File LINE1
    command {
        cat ${SVA} |grep "#" > ${Fam}.header.txt
        cat ${SVA} |grep -v "#" > ${Fam}.sva.vcf
        cat ${LINE1} |grep -v "#"> ${Fam}.line1.vcf
        cat ${ALU} |grep -v "#"> ${Fam}.alu.vcf
        cat ${Fam}.header.txt ${Fam}.sva.vcf ${Fam}.line1.vcf ${Fam}.alu.vcf |sed 's/${Fam}fa/${Fa}/g'|sed 's/${Fam}mo/${Mo}/g'|sed 's/${Fam}p1/${P1}/g' |sed 's/${Fam}s1/${S1}/g' | vcf-sort -c |bgzip -c > melt.${Fam}.vcf.gz
        tabix -p vcf melt.${Fam}.vcf.gz
    }
    runtime{
        cpu: "1"
        memory: "4 GB"
        queue: "short"
        sla: "-sla miket_sc"
    }
    output{
        File Melt="melt.${Fam}.vcf.gz"
        File Index="melt.${Fam}.vcf.gz.tbi"
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