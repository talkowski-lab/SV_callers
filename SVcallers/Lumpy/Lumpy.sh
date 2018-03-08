#!/bin/bash
set -e 
# This is the master script for running lumpy-sv (v0.2.13)
# The code assumes existence of /lumpy-sv/scripts/pairend_distro.py script
# This also assumes that lumpy is in PATH
# For detailed options use ./Lumpy.sh
# output is .bedpe file 
# Example usage:
# $./Lumpy.sh -p ../Rawdata/14415.fa.bam -s ../Rawdata/14415.fa.bam
# Load neccessary modules
# 322 2017 disable genotyping
module use /apps/modulefiles/lab/miket
module load sambamba/0.6.1
help_message()
{
echo -e "./Lumpy.sh -s[split read bam files,optional] s1.bam,s2.bam,... \n
 -p[paired end bam files, optional] s1.bam,s2.bam,... \n  
 -m[min map, optional,default:1] -b [back distance,optional,default:20]\n
 -b[bam files]
 -t [trim threshold,optional,default:1e-3] -r[read distance,optional,default:150]\n
 -l [lumpy-sv directory, optional, default:/PHShome/hw878/Software/lumpy-sv]\n
 -o[output tag,optional,default="lumpy_output"]\n
 -d[output directory,optional,default="."]\n"
}
# Default variables
PE_FLAG=0
SR_FLAG=0
OUT_DIR="."
LUMPY_DIR=/PHShome/hw878/Software/lumpy-sv
BLACKLIST=/data/talkowski/rlc47/src/b37.lumpy.exclude.4-13.bed
OUT="lumpy_output"
WEIGHT=4
Z=4
MIN_MAP_T=20
BACK=20
TT=0
READ_LENGTH=151 # input parameter, default should be 151
FLAG=0  # need at least one bam
# Parse arguments
if [ $# -eq 0 ];
then
    help_message
    exit 1
else
    while getopts ":hb:s:p:m:z:t:r:o:d:l:" opt; do
        case $opt in
            h ) help_message
                exit 0 ;;
            b ) echo "bams = $OPTARG "
                FLAG=1
                set -f # disable glob
                IFS=',' # split on space characters
                bam_array=($OPTARG) ;; # use the split+glob operator
            s ) echo "split read bams = $OPTARG "
                FLAG=1
                set -f # disable glob
                IFS=',' # split on space characters
                sr_array=($OPTARG) ;; # use the split+glob operator
            p ) echo "paired end bams = $OPTARG "
                FLAG=1
                set -f # disable glob
                IFS=',' # split on space characters
                pe_array=($OPTARG) ;; # use the split+glob operator
            m ) echo "min_mapping_threshold = $OPTARG" 
                MIN_MAP_T=$OPTARG ;;
            z ) echo "shadow list" 
                BLACKLIST=$OPTARG ;;
            t ) echo "trim threshold = $OPTARG" 
                TT=$OPTARG ;;
            r ) echo "read length = $OPTARG" 
                READ_LENGTH=$OPTARG ;;
            o ) echo "output tag = $OPTARG" 
                OUT=$OPTARG ;;
            d ) echo "output directory = $OPTARG" 
                OUT_DIR=$OPTARG 
                mkdir -p $OUT_DIR ;; 
            l ) echo "lumpy-sv directory = $OPTARG" 
                LUMPY_DIR=$OPTARG 
                ;;
            * ) help_message
                exit 1 ;;
        esac
    done
fi
if [ ! -f "$LUMPY_DIR/scripts/pairend_distro.py" ];
                then
                    echo "$LUMPY_DIR/scripts/pairend_distro.py not found" 
                    exit 1 
                fi
if [ $FLAG -eq 0 ];
then 
    echo "At least one bam file needed."
    exit 1
fi
# Populate pe_option_array
if [ ${pe_array+x} ];  # if at least one paried end bam exist
then 
    pe_option_array=("")
    echo "Paired end bam exist, populating options"
    i=0
    for PE_BAM in ${pe_array[@]}; 
    do
        BAM=${bam_array[i]}
        OUT_FILE=`basename $BAM .bam`
        MEAN_STDEV=`sambamba view $BAM \
                | $LUMPY_DIR/scripts/pairend_distro.py \
                    -r $READ_LENGTH \
                    -X $Z \
                    -N 10000 \
                    -o $OUT_DIR/$OUT_FILE.histo`
        echo $MEAN_STDEV
        MEAN=`echo $MEAN_STDEV | cut -f1 | cut -d ":" -f2`
        STDEV=`echo $MEAN_STDEV | cut -f2 | cut -d ":" -f2`
        pe_option_array+=("-pe bam_file:$PE_BAM,histo_file:$OUT_DIR/$OUT_FILE.histo,mean:$MEAN,stdev:$STDEV,read_length:$READ_LENGTH,min_non_overlap:$READ_LENGTH,discordant_z:4,back_distance:$BACK,weight:1,id:$OUT_FILE,min_mapping_threshold:$MIN_MAP_T")
        ((i+=1))
    done
fi
# Populate sr_option_array
if [ ${sr_array+x} ]; 
then
    sr_option_array=("")
    echo "Split read exists, populating options"
    i=0
    for SR_BAM in ${sr_array[@]}; 
    do 
        BAM=${bam_array[i]}
        OUT_FILE=`basename $BAM .bam`
        sr_option_array+=("-sr bam_file:$SR_BAM,back_distance:$BACK,weight:1,id:$OUT_FILE,min_mapping_threshold:$MIN_MAP_T")
        ((i+=1))
        done
fi
#Running Lumpy
echo "Running Lumpy"
unset IFS
# echo "${sr_option_array[1]}"
# a=$(echo "${sr_option_array[1]}")
# echo $a
sr_option=$(echo "${sr_option_array[@]}")
pe_option=$(echo "${pe_option_array[@]}")
echo $sr_option
cmd="lumpy -mw $WEIGHT -tt $TT -t tmp -x $BLACKLIST $sr_option $pe_option > $OUT_DIR/$OUT.vcf"
echo $cmd
eval $cmd
# genocmd_array=("cat $OUT_DIR/$OUT.vcf|")
# i=0
# for BAM in ${bam_array[@]};
# do 
    # SR_BAM=${sr_array[i]}
    # genocmd_array+=("svtyper -B $BAM -S $SR_BAM |")
    # ((i+=1))
    # done
# genocmd_array+=("cat > $OUT_DIR/$OUT.geno.vcf")
# genocmd=$(echo "${genocmd_array[@]}")
# echo $genocmd
# eval $genocmd

