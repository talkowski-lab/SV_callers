import "/data/talkowski/hw878/Standard_workflow/Bwa/Bam-cram_conversion/CramToBam/ScatterRG.wdl" as ScrRG
workflow Cram2Bam {
# This workflow was used to run the GATK pipeline for the twins study. BWA is called single sample 
  File inputSamplesFile
  Array[Array[File]] inputSamples = read_tsv(inputSamplesFile)
  String refFasta
  String refIndex
  call GenChrList{input: refindex=refIndex}
  scatter (sample in inputSamples) {
    call getRGlist { 
      input: 
          BamFile=sample[1],
          BamIndex=sample[2],
          sampleName=sample[0]
    }
    call ScrRG.work{
      input: 
          BamFile=sample[1],
          BamIndex=sample[2],
          RGfile=getRGlist.rglist,
          sampleName=sample[0], 
          RefFasta=refFasta
        }
    }
}



task getRGlist {
  String sampleName
  File BamFile
  File BamIndex
    command {samtools view -H ${BamFile} | grep "@RG" > RGlist.txt
    }
  output {
        File rglist = "RGlist.txt"
    }
  runtime {
    memory: "4 GB"
    cpu: "1"
    queue: "vshort"
  }
}
task GenChrList{
    File refindex
    command{
        cut -f 1 ${refindex} >chrlist.txt
    }
    output{
        File chrList="chrlist.txt"
    }
    runtime {
        memory: "4 GB"
        cpu: "1"
        queue:"short"
    }
}