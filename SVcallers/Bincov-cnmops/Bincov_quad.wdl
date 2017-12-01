import "/data/talkowski/hw878/Standard_workflow/SVcallers/Bincov-cnmops/Bincov_samples.wdl" as BCsample
workflow Bincov {
    File Filelist
    File chrlist
    Array[Array[String]] Fams = read_tsv(Filelist)
    scatter(Fam in Fams){
        call BCsample.BC_sample as BCfather {input: bamfile=Fam[1],Chrlist=chrlist}
        call BCsample.BC_sample as BCmother {input: bamfile=Fam[2],Chrlist=chrlist}
        call BCsample.BC_sample as BCproband {input: bamfile=Fam[3],Chrlist=chrlist}
        call BCsample.BC_sample as BCsib {input: bamfile=Fam[4],Chrlist=chrlist}
    }
}
