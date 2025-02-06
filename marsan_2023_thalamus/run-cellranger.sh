#!/usr/bin/env bash
#SBATCH --time 16:00:00
#SBATCH --mem 64G
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 24
#SBATCH --gres=lscratch:500

module load cellranger/8.0.1

PROJDIR="/data/CARD_MPU/data/marsan_2023_thalamus"
cd ${PROJDIR}
TMPDIR="/lscratch/${SLURM_JOB_ID}"
REF='/fdb/cellranger/refdata-cellranger-2024-A/refdata-gex-GRCh38-2024-A'

N=${SLURM_ARRAY_TASK_ID}

SRA=$(sed -n ${N}p samples.txt | awk '{print $1}' )
SID=$(sed -n ${N}p samples.txt | awk '{print $2}' )

OUTDIR="CELLRANGER/${SID}"
mkdir -p ${OUTDIR}
OUTDIR=$(realpath ${OUTDIR})

# --id is for naming outputs
# --sample is for matching fastq file names
MYCMD=( cellranger count \
        --id ${SID} \
        --transcriptome ${REF} \
        --sample ${SRA} \
        --create-bam true \
        --localcores 22 \
        --localmem 60
)

j=$(realpath FASTQS)
MYCMD+=( "--fastqs $j" )

cd ${TMPDIR}

# Run command
echo -e "Running:\n${MYCMD[@]}"
${MYCMD[@]}

# Move final files
cp ${SID}/outs/possorted_genome_bam.bam ${OUTDIR}
cp ${SID}/outs/possorted_genome_bam.bam.bai ${OUTDIR}
cp ${SID}/outs/filtered_feature_bc_matrix.h5 ${OUTDIR}
cp ${SID}/outs/metrics_summary.csv ${OUTDIR}

cd
