#!/usr/bin/env bash
#SBATCH --job-name=jellyfish_histo_arabidopsis
#SBATCH --output=logs/03_hist_%j.out
#SBATCH --error=logs/03_hist_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=50G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pibu_el8

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/jellyfish-2.2.6--0.sif"
INPUT_DIR="${PROJECT_DIR}/results/02_count"
OUTPUT_DIR="${PROJECT_DIR}/results/03_hist"

mkdir -p "${OUTPUT_DIR}"

# Execute histogram
apptainer exec --bind /data "${CONTAINER}" jellyfish histo \
    -t "${SLURM_CPUS_PER_TASK}" "${INPUT_DIR}/reads.jf" > "${OUTPUT_DIR}/reads.histo"

if [ $? -ne 0 ]; then
    echo "Jellyfish histo failed!" >&2
    exit 1
fi

echo "Task complete! Finished at $(date)"