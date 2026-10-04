#!/usr/bin/env bash
#SBATCH --job-name=fastQC_arabidopsis_samples
#SBATCH --output=logs/01_fastqc_%j.out
#SBATCH --error=logs/01_fastqc_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pshort_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/fastqc-0.12.1.sif"
INPUT_DIR_1="${PROJECT_DIR}/data/Mh-0"
INPUT_DIR_2="${PROJECT_DIR}/data/RNAseq_Sha"
OUTPUT_DIR_1="${PROJECT_DIR}/results/01_QC/Genome"
OUTPUT_DIR_2="${PROJECT_DIR}/results/01_QC/RNA"


mkdir -p "${OUTPUT_DIR_1}"
mkdir -p "${OUTPUT_DIR_2}"


# Run FastQC for Mh-0
apptainer exec --bind /data "${CONTAINER}" fastqc \
    "${INPUT_DIR_1}"/*.fastq.gz \
    -o "${OUTPUT_DIR_1}" \
    -t "${SLURM_CPUS_PER_TASK}"


# Run FastQC for RNA
apptainer exec --bind /data "${CONTAINER}" fastqc \
    "${INPUT_DIR_2}"/*.fastq.gz \
    -o "${OUTPUT_DIR_2}" \
    -t "${SLURM_CPUS_PER_TASK}"

if [ $? -ne 0 ]; then
    echo "FastQC failed for Mh-0!" >&2
    exit 1
fi


echo "Task complete! Finished at $(date)"