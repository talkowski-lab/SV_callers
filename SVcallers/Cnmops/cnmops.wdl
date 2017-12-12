workflow cnmops{
    File Chromfile
    File Allofile
    String DIR
    Array[Array[String]] Chroms =read_tsv(Chromfile)
    Array[Array[String]] Allos =read_tsv(Allofile)
    File Pedfile
    File samplepy
    Array[Array[String]]Peds=read_tsv(Pedfile)
    scatter (Chrom in Chroms){
        call CNsample_normal as Normal3{input: chr=Chrom[0],ped=Pedfile,mode="normal",r="3",dir=DIR,pyscript=samplepy}
        call CNsample_normal as Normal10{input: chr=Chrom[0],ped=Pedfile,mode="normal",r="10",dir=DIR,pyscript=samplepy}
    }
    scatter (Allo in Allos){
        call CNsample_normal as Male3 {input: chr=Chrom[0],ped=Pedfile,mode="male",r="3",dir=DIR,pyscript=samplepy}
        call CNsample_normal as Male10 {input: chr=Chrom[0],ped=Pedfile,mode="male",r="10",dir=DIR,pyscript=samplepy}
        call CNsample_normal as Female3{input: chr=Chrom[0],ped=Pedfile,mode="female",r="3",dir=DIR,pyscript=samplepy}
        call CNsample_normal as Female10{input: chr=Chrom[0],ped=Pedfile,mode="female",r="10",dir=DIR,pyscript=samplepy}
    }
    call Cleancnmops{input: samplelist=Pedfile,N3=Normal3.Gff,N10=Normal10.Gff,M3=Male3.Gff,M10=Male10.Gff,F3=Female3.Gff,F10=Female10.Gff}
}

task CNsample_normal{
    File pyscript
    String chr
    File ped
    String mode
    String r
    String dir
    command{
        python /data/talkowski/hw878/Prenatal/cnmops/genmakemtrixinput.py ${ped} ${chr} ${mode} ${dir} > sample.txt
        bash /PHShome/hw878/Software/WGD/bin/cnMOPS_workflow.sh -r ${r} -o . sample.txt
    }
    output{
        File Gff="calls/cnMOPS.cnMOPS.gff"
    }
  runtime {
    memory: "60 GB"
    cpu: "1"
    queue:"big"
    sla:"-sla miket_sc"
  }
}
task Cleancnmops{
    File samplelist
    Array[File?] N3
    Array[File?] N10
    Array[File?] M3
    Array[File?] M10
    Array[File?] F3
    Array[File?] F10
    command{
        cut -f2 ${samplelist} > sample.list
        cat ${sep=" " N3} ${sep=" " N10} ${sep=" " M3} ${sep=" " M10} ${sep=" " F3} ${sep=" " F10} > cnmops.gff
        # cat ${sep=" " N3} > test.out
        mkdir calls
        grep -v "#" cnmops.gff > cnmops.gff1
        echo "./cnmops.gff1">GFF.list
        /PHShome/hw878/Software/WGD/bin/cleancnMOPS.sh -z \
        -o calls/ sample.list GFF.list
    }
    # output{
        # File DEL="${Sample}.cnMOPS.DEL.bed.gz"
        # File DUP="${Sample}.cnMOPS.DUP.bed.gz"
    # }
  runtime {
    memory: "8 GB"
    cpu: "1"
    queue:"long"
    sla:"-sla miket_sc"
  }
}