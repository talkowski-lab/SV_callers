import "/data/talkowski/hw878/Standard_workflow/SVcallers/Bincov-cnmops/Bincov_samples.wdl" as BCsample
workflow Bincov {
    File Filelist
    File CHRLIST
    Array[Array[String]] Fams = read_tsv(Filelist)
    scatter(Fam in Fams){
        call BCsample.BC_sample as BCfather {input: bamfile=Fam[1],Chrlist=CHRLIST}
        call BCsample.BC_sample as BCmother {input: bamfile=Fam[2],Chrlist=CHRLIST}
        call BCsample.BC_sample as BCproband {input: bamfile=Fam[3],Chrlist=CHRLIST}
        call gather{input:Fa=BCfather.bc,Mo=BCmother.bc,P1=BCproband.bc}
    }
    call combine{input:Dirs=gather.absdir}
    output{
        String DIR=combine.absdir
    }
}
task gather{
    Array[File] Fa
    Array[File] Mo
    Array[File] P1
    command<<<
        mkdir Bincov_results
        cp {${sep="," Fa},} Bincov_results
        cp {${sep="," Mo},} Bincov_results
        cp {${sep="," P1},} Bincov_results
        str=`readlink -f Bincov_results`
        echo $str>out.tmp
    >>>
    output {
        String absdir = read_string("out.tmp")
    }
    runtime {
        memory: "4 GB"
        cpu: "1"
        queue:"short"
        sla:"-sla miket_sc"
    }
}
task combine{
    Array[String] Dirs
    command<<<
        mkdir Bincov_result
        cp {${sep="/*," Dirs}/*,} Bincov_result
        str=`readlink -f Bincov_results`
        echo $str>out.tmp
    >>>
    output {
        String absdir = read_string("out.tmp")
        Array[File] bincov=glob("Bincov_result/*")
    }
    runtime {
        memory: "4 GB"
        cpu: "1"
        queue:"short"
        sla:"-sla miket_sc"
    }
}