workflow GATK {
# This workflow was used to run the GATK pipeline for the twins study. BWA is called single sample 
  File inputSamplesFile
  Array[Array[File]] inputSamples = read_tsv(inputSamplesFile)
  File refFasta
  File refIndex
  File refDict
  File refAmb
  File refAnn
  File refBwt
  File refPac
  File refSa
  File gatk
  File knownSNP
  File knownSNPIndex
  File knownIndel
  File knownIndelIndex
  File dbSNP
  File dbSNPIndex
  File millsIndel
  File millsIndelIndex
  File omniSNP
  File omniSNPIndex
  File hapmapSNP
  File hapmapSNPIndex
  File kgSNP
  File kgSNPIndex
  String Samplename
  scatter (sample in inputSamples) {
    call HaplotypeCaller { 
      input: 
          BamFile=sample[1],
          BamIndex=sample[2],
          sampleName=sample[0], 
          RefFasta=refFasta, 
          RefIndex=refIndex,
          RefAmb=refAmb,
          GATK=gatk,
          RefDict= refDict,
          RefAmb= refAmb,
          RefAnn=refAnn,
          RefBwt=refBwt,
          RefPac=refPac,
          RefSa=refSa,
          KnownSNP=knownSNP,
          KnownSNPIndex=knownSNPIndex,
          KnownIndel=knownIndel,
          KnownIndelIndex=knownIndelIndex,
    }  
  }
  call GenotypeGVCFs { 
  input: GVCFs=HaplotypeCaller.GVCF, 
      sampleName=Samplename, 
      RefFasta=refFasta, 
      GATK=gatk, 
      RefIndex=refIndex, 
      RefDict=refDict 
  }
  call BuildSNPModel {
    input: GATK=gatk,
      RefFasta=refFasta,
      RefIndex=refIndex,
      RefDict=refDict,
      RawVariants=GenotypeGVCFs.rawVCF,
      RawVariantsIndex=GenotypeGVCFs.rawIndex,
      DbSNP=dbSNP,
      DbSNPIndex=dbSNPIndex,
      OmniSNP=omniSNP,
      OmniSNPIndex=omniSNPIndex,
      HapmapSNP=hapmapSNP,
      HapmapSNPIndex=hapmapSNPIndex,
      KGSNP=kgSNP,
      KGSNPIndex=kgSNPIndex,
      SampleName=Samplename
  }
  call ApplySNPModel {
    input: RawVariants=GenotypeGVCFs.rawVCF,
      RawVariantsIndex=GenotypeGVCFs.rawIndex,
      GATK=gatk,
      RefFasta=refFasta,
      RefIndex=refIndex,
      RefDict=refDict,
      Recal=BuildSNPModel.RECAL,
      Tranche=BuildSNPModel.TRANCHE,
      SampleName=Samplename
  }
  call BuildIndelModel {
    input: GATK=gatk,
      RefFasta=refFasta,
      RefIndex=refIndex,
      RefDict=refDict,
      RawIndelVcf=ApplySNPModel.VCF,
      RawIndelVcfIndex=ApplySNPModel.IDX,
      MillsIndel=millsIndel,
      MillsIndelIndex=millsIndelIndex,
      SampleName=Samplename
  }
  call ApplyIndelModel {
    input: RawIndelVcf=ApplySNPModel.VCF,
      RawIndelVcfIndex=ApplySNPModel.IDX,
      GATK=gatk,
      RefFasta=refFasta,
      RefIndex=refIndex,
      RefDict=refDict,
      Recal=BuildIndelModel.RECAL,
      Tranche=BuildIndelModel.TRANCHE,
      SampleName=Samplename
  }
  
}

task HaplotypeCaller {
  File BamFile
  File BamIndex
  File RefFasta
  File RefIndex
  File RefDict
  File RefAmb
  File RefAnn
  File RefBwt
  File RefPac
  File RefSa
  File GATK
  File KnownSNP
  File KnownSNPIndex
  File KnownIndelIndex
  File KnownIndel
  String sampleName
  command {
    java -Xmx8000m -Djava.io.tmpdir=`pwd`/tmp -jar ${GATK} \
        -T BaseRecalibrator \
        -nct 4\
        -R ${RefFasta} \
        -I ${BamFile} \
        -knownSites ${KnownSNP} \
        -knownSites ${KnownIndel} \
        -o ${sampleName}_recal_data.table
    java -Xmx8000m -jar -Djava.io.tmpdir=`pwd`/tmp ${GATK} \
        -T HaplotypeCaller \
        -ERC GVCF \
        -R ${RefFasta} \
        -I ${BamFile}  \
        -bamout bamout.bam \
        -BQSR ${sampleName}_recal_data.table \
        -o ${sampleName}_rawLikelihoods.g.vcf 
  }
  output {
    File GVCF = "${sampleName}_rawLikelihoods.g.vcf"
  }
  runtime {
    memory: "20 GB"
    cpu: "4"
    queue: "big"
    sla: "-sla miket_sc"
  }
}
task GenotypeGVCFs {

  File GATK
  File RefFasta
  File RefIndex
  File RefDict

  String sampleName
  Array[File] GVCFs

  command {
    java -jar ${GATK} \
        -nt 4
        -T GenotypeGVCFs \
        -R ${RefFasta} \
        -V ${sep=" -V " GVCFs} \
        -o ${sampleName}_rawVariants.vcf
  }
  output {
    File rawVCF = "${sampleName}_rawVariants.vcf"
    File rawIndex = "${sampleName}_rawVariants.vcf.idx"
  }
  runtime {
    memory: "20 GB"
    cpu: "4"
    queue:"big"
  }
  
}
task BuildSNPModel {

  File GATK
  File RefFasta
  File RefIndex
  File RefDict
  File RawVariants
  File RawVariantsIndex
  File DbSNP
  File DbSNPIndex
  File OmniSNP
  File OmniSNPIndex
  File HapmapSNP
  File HapmapSNPIndex
  File KGSNP
  File KGSNPIndex
  String SampleName

  command {
    java -Xmx11g -jar -Djava.io.tmpdir=`pwd`/tmp -jar ${GATK} \
        -T VariantRecalibrator \
        -R ${RefFasta} \
        -input ${RawVariants} \
        -resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${HapmapSNP} \
        -resource:omni,known=false,training=true,truth=true,prior=12.0 ${OmniSNP} \
        -resource:KG,known=false,training=true,truth=false,prior=10.0 ${KGSNP} \
        -resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${DbSNP} \
        -an DP\
        -an MQ\
        -an FS\
        -an QD\
        -an SOR\
        -an MQRankSum\
        -an ReadPosRankSum\
        -mode SNP \
        -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 \
        -recalFile ${SampleName}_recalibrate_SNP.recal \
        -tranchesFile ${SampleName}_recalibrate_SNP.tranches \
        -rscriptFile ${SampleName}_recalibrate_SNP_plots.R
        }
    runtime {
    memory: "8 GB"
    cpu: "1"
    queue: "medium"
  }
  output {
    File TRANCHE = "${SampleName}_recalibrate_SNP.tranches"
    File RECAL = "${SampleName}_recalibrate_SNP.recal"
  }
}

task ApplySNPModel {
  File RawVariants
  File RawVariantsIndex
  File GATK
  File RefFasta
  File RefIndex
  File RefDict
  File Recal
  File Tranche
  String SampleName

  command {
    java -Xmx11g -jar -Djava.io.tmpdir=`pwd`/tmp -jar ${GATK} \
        -T ApplyRecalibration \
        -R ${RefFasta} \
        -input ${RawVariants} \
        -mode SNP \
        --ts_filter_level 99.0 \
        -recalFile ${Recal} \
        -tranchesFile ${Tranche} \
        -o ${SampleName}_recalibrated_snps_raw_indels.vcf 
  }
  runtime {
    memory: "8 GB"
    cpu: "1"
    queue: "medium"
  }
  output {
    File VCF = "${SampleName}_recalibrated_snps_raw_indels.vcf"
    File IDX = "${SampleName}_recalibrated_snps_raw_indels.vcf.idx"
  }
}
task BuildIndelModel {
  File MillsIndel
  File MillsIndelIndex
  File GATK
  File RefFasta
  File RefIndex
  File RefDict
  File RawIndelVcf
  File RawIndelVcfIndex
  String SampleName

  command {
    java -Xmx4g -jar -Djava.io.tmpdir=`pwd`/tmp -jar ${GATK} \
        -T VariantRecalibrator \
        -R ${RefFasta} \
        -input ${RawIndelVcf} \
        -resource:mills,known=true,training=true,truth=true,prior=12.0 ${MillsIndel} \
        -an DP\
        -an FS\
        -an QD\
        -an SOR\
        -an MQRankSum\
        -an ReadPosRankSum\
        -mode INDEL \
        -tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 \
        --maxGaussians 4 \
        -recalFile ${SampleName}_recalibrate_INDEL.recal \
        -tranchesFile ${SampleName}_recalibrate_INDEL.tranches \
        -rscriptFile ${SampleName}_recalibrate_INDEL_plots.R 
    }
    runtime {
        memory: "8 GB"
        cpu: "1"
        queue:"medium"
    }
    output {
        File RECAL = "${SampleName}_recalibrate_INDEL.recal"
        File TRANCHE = "${SampleName}_recalibrate_INDEL.tranches"
    }
}
task ApplyIndelModel {
  File RawIndelVcf
  File RawIndelVcfIndex
  File GATK
  File RefFasta
  File RefIndex
  File RefDict
  File Recal
  File Tranche
  String SampleName
  command {
    java -Xmx3g -jar -Djava.io.tmpdir=`pwd`/tmp -jar ${GATK} \
        -T ApplyRecalibration \
        -R ${RefFasta} \
        -input ${RawIndelVcf} \
        -mode INDEL \
        --ts_filter_level 99.0 \
        -recalFile ${Recal}\
        -tranchesFile ${Tranche} \
        -o ${SampleName}_recalibrated_variants.vcf 
        }
    runtime {
    memory: "8 GB"
    cpu: "1"
    queue: "medium"
    }
    output {
        File VCF = "${SampleName}_recalibrated_variants.vcf"
        File IDX = "${SampleName}_recalibrated_variants.vcf.idx"
    }
}
