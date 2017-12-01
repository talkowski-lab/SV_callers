import "/data/talkowski/hw878/Standard_workflow/SVcallers/Bincov-cnmops/Bincov_samples.wdl" as BCsample
workflow Bincov {
    File Filelist
    File CHRLIST
    Array[Array[String]] Fams = read_tsv(Filelist)
    scatter(Fam in Fams){
        call BCsample.BC_sample as BCfather {input: bamfile=Fam[1],Chrlist=CHRLIST}
        call BCsample.BC_sample as BCmother {input: bamfile=Fam[2],Chrlist=CHRLIST}
        call BCsample.BC_sample as BCproband {input: bamfile=Fam[3],Chrlist=CHRLIST}
    }
}
