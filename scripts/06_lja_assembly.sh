#!/usr/bin/env bash
#SBATCH --job-name=lja_arabidopsis
#SBATCH --output=logs/06_lja_%j.out
#SBATCH --error=logs/06_lja_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8


# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/lja-0.2.sif" # set this path to your choice of container
INPUT_DIR="${PROJECT_DIR}/data/Qar-8a"
OUTPUT_DIR="${PROJECT_DIR}/results/06_lja_assembly"

# Create directory in results
mkdir -p "${PROJECT_DIR}"/results/06_lja_assembly

# Run LJA assembly (PacBio HiFi reads)
apptainer exec --bind /data "${CONTAINER}" lja \
    --reads "${INPUT_DIR}"/*.fastq.gz \
    -o "${OUTPUT_DIR}" \
    -t "${SLURM_CPUS_PER_TASK}"

if [ $? -ne 0 ]; then
    echo "LJA failed!" >&2
    exit 1
fi

echo "Task complete! Finished at $(date)""
