#!/usr/bin/env bash
#SBATCH --job-name=trinity_arabidopsis
#SBATCH --output=logs/07_trinity_%j.out
#SBATCH --error=logs/07_trinity_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
INPUT_DIR="${PROJECT_DIR}/data/RNAseq_Sha"
OUTPUT_DIR="${PROJECT_DIR}/results/07_trinity_assembly"

mkdir -p "${OUTPUT_DIR}"

# Load Trinity module
module load Trinity/2.15.1-foss-2021a

# Run Trinity (paired-end RNA-seq)
Trinity \
    --seqType fq \
    --max_memory 64G \
    --left "${INPUT_DIR}"/*_1.fastq.gz \
    --right "${INPUT_DIR}"/*_2.fastq.gz \
    --CPU "${SLURM_CPUS_PER_TASK}" \
    --output "${OUTPUT_DIR}"

if [ $? -ne 0 ]; then
    echo "Trinity failed!" >&2
    exit 1
fi

echo "Task complete! Finished at $(date)"