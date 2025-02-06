#!/usr/bin/env bash
#SBATCH --time 16:00:00
#SBATCH --mem 64G
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 24
#SBATCH --gres=lscratch:500

module load cellranger/8.0.1

PROJDIR="/data/CARD_MPU/biogen"
cd ${PROJDIR}
TMPDIR="/lscratch/${SLURM_JOB_ID}"
REF='/fdb/cellranger/refdata-cellranger-2024-A/refdata-gex-GRCh38-2024-A'

N=${SLURM_ARRAY_TASK_ID}

SID=$(sed -n ${N}p samples.txt)
OUTDIR="CELLRANGER/${SID}"
mkdir -p ${OUTDIR}
OUTDIR=$(realpath ${OUTDIR})

# CHANGE OUTPUT DIR BACK TO LSCRATCH
MYCMD=( cellranger count \
        --id ${SID} \
        --transcriptome ${REF} \
        --sample ${SID} \
        --create-bam true \
        --localcores 22 \
        --localmem 60
)

dirs=(
FASTQS/210517_A01092_0085_BH2CVKDSX2/fastq
FASTQS/210518_A01092_0087_BHCFNGDSX2/fastq
FASTQS/210525_A01092_0089_AHVNT7DMXX/fastq
)

for i in ${dirs[@]}; do
    j=$(realpath $i)
    MYCMD+=( "--fastqs $j" )
done

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
