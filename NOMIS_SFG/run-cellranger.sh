#!/usr/bin/env bash
#SBATCH --time 16:00:00
#SBATCH --mem 64G
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 24
#SBATCH --gres=lscratch:500


# exclude 
module load cellranger/8.0.1


PROJDIR="/data/CARD_MPU/data/NOMIS_SFG"
cd ${PROJDIR}
TMPDIR="/lscratch/${SLURM_JOB_ID}"
REF='/fdb/cellranger/refdata-cellranger-2024-A/refdata-gex-GRCh38-2024-A'
SAMPLESHEET='samplesheet.tsv'
DELIM='\t'

#let N=${SLURM_ARRAY_TASK_ID}+1
N=${SLURM_ARRAY_TASK_ID}
let N=${N}+1

SID=$(sed -n ${N}p ${SAMPLESHEET} | awk -F ${DELIM} '{print $11}')
IID=$(sed -n ${N}p ${SAMPLESHEET} | awk -F ${DELIM} '{print $2}')


OUTDIR="CELLRANGER/${IID}"
mkdir -p ${OUTDIR}
OUTDIR=$(realpath ${OUTDIR})

# --sample refers to the fastq filename prefix before _S#_L00#_R#_001.fastq.gz
# --id is what you want it named for output purposes
# CHANGE OUTPUT DIR BACK TO LSCRATCH
MYCMD=( cellranger count \
        --id ${IID} \
        --transcriptome ${REF} \
        --sample ${SID} \
        --create-bam true \
        --localcores 22 \
        --localmem 60
)

# Note: -L option tells `find` to follow symbolic links
# Only return dirs that actually contain this sample
dirs=($(find -L FASTQS \
    -maxdepth 2 \
    -type f \
    -name "*${SID}_S*.fastq.gz" \
    -exec dirname {} \; | \
    sort -u ))

for i in ${dirs[@]}; do
    j=$(realpath $i)
    MYCMD+=( "--fastqs $j" )
done

cd ${TMPDIR}

# Run command
echo -e "Running:\n${MYCMD[@]}"
${MYCMD[@]}

# Move final files
cp ${IID}/outs/possorted_genome_bam.bam ${OUTDIR}
cp ${IID}/outs/possorted_genome_bam.bam.bai ${OUTDIR}
cp ${IID}/outs/filtered_feature_bc_matrix.h5 ${OUTDIR}
cp ${IID}/outs/metrics_summary.csv ${OUTDIR}

cd
