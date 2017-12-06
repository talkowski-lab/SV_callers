workflow BC_sample{
    String bamfile
    File Chrlist
    # String Samplename
    Array[Array[String]]Chrs=read_tsv(Chrlist)
    scatter(Chr in Chrs){
        call BincovChr{input: Bamfile=bamfile,chr=Chr[0]}
    }
    output{
        Array[File] bc =BincovChr.bc
    }
}

task BincovChr{
    String Bamfile
    # String sample
    String Name=basename(Bamfile,".bam")
    String chr
    command{
        python /PHShome/hw878/Software/WGD/bin/binCov.py ${Bamfile} ${chr} ${Name}_${chr}.bed -b 100 -z
    }
    output{
        File bc="${Name}_${chr}.bed.gz"
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue:"medium"
        sla:"-sla miket_sc"
    }
}
