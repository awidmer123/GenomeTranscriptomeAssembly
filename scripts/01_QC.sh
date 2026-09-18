#!/usr/bin/env bash
#SBATCH --job-name=fastQC_arabidopsis_samples
#SBATCH --output=logs/01_fastqc_%j.out
#SBATCH --error=logs/01_fastqc_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pshort_el8

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/fastqc-0.12.1.sif"
INPUT_DIR_1="${PROJECT_DIR}/data/Qar-8a"
INPUT_DIR_2="${PROJECT_DIR}/data/RNASeq_Sha"
OUTPUT_DIR="${PROJECT_DIR}/results/1_QC"

mkdir -p "${OUTPUT_DIR}"

# Run FastQC for Qar-8a
apptainer exec --bind /data "${CONTAINER}" fastqc \
    "${INPUT_DIR_1}"/*.fastq.gz \
    "${INPUT_DIR_2}"/*.fastq.gz \
    -o "${OUTPUT_DIR}" \
    -t "${SLURM_CPUS_PER_TASK}"

if [ $? -ne 0 ]; then
    echo "FastQC failed for Qar-8a!" >&2
    exit 1
fi


echo "Task complete! Finished at $(date)"