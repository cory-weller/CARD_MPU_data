#!/usr/bin/env bash
#SBATCH --time 16:00:00
#SBATCH --mem 64G
#SBATCH --ntasks 1
#SBATCH --cpus-per-task 24
#SBATCH --gres=lscratch:500

module load cellranger/8.0.1

SAMPLEFILE='samples_SRA_table.txt'

PROJDIR="/data/CARD_MPU/data/li_2023"
cd ${PROJDIR}
TMPDIR="/lscratch/${SLURM_JOB_ID}"
REF='/fdb/cellranger/refdata-cellranger-2024-A/refdata-gex-GRCh38-2024-A'

N=${SLURM_ARRAY_TASK_ID}

SID=$(sed -n ${N}p ${SAMPLEFILE} | cut -d ' ' -f 1)
SRA1=$(sed -n ${N}p ${SAMPLEFILE} | cut -d ' ' -f 2)
SRA2=$(sed -n ${N}p ${SAMPLEFILE} | cut -d ' ' -f 3)
SRA3=$(sed -n ${N}p ${SAMPLEFILE} | cut -d ' ' -f 4)
SRA4=$(sed -n ${N}p ${SAMPLEFILE} | cut -d ' ' -f 5)

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
FASTQ/${SRA1}
FASTQ/${SRA2}
FASTQ/${SRA3}
FASTQ/${SRA4}
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
