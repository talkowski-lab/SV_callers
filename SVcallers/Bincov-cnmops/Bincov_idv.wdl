import "/data/talkowski/hw878/Standard_workflow/SVcallers/Bincov-cnmops/Bincov_samples.wdl" as BCsample
workflow Bincov {
    File Filelist
    File chrlist
    String Bamfiledir
    Array[Array[String]] Fams = read_tsv(Filelist)
    scatter(Fam in Fams){
        call BCsample.BC_sample as BCproband {input: bamfiledir=Bamfiledir,bamfile=Fam[1],Chrlist=chrlist}
    }
}
