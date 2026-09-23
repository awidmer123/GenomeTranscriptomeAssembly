#!/usr/bin/env bash
#SBATCH --job-name=flye_arabidopsis
#SBATCH --output=logs/04_flye_%j.out
#SBATCH --error=logs/04_flye_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/flye_2.9.5.sif" # set this path to your choice of container
INPUT_DIR="${PROJECT_DIR}/data/Mh-0"
OUTPUT_DIR="${PROJECT_DIR}/results/04_flye_assembly"

# Create directory in results
mkdir -p "${PROJECT_DIR}"/results/04_flye_assembly

# Run Flye assembly (PacBio HiFi reads)
apptainer exec --bind /data "${CONTAINER}" flye \
    --pacbio-hifi "${INPUT_DIR}"/*.fastq.gz \
    --genome-size 130m \
    --out-dir "${OUTPUT_DIR}" \
    --threads "${SLURM_CPUS_PER_TASK}"

echo "Task complete! Finished at $(date)""





