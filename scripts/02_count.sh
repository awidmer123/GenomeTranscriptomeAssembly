#!/usr/bin/env bash
#SBATCH --job-name=jellyfish_count_arabidopsis
#SBATCH --output=logs/02_jellyfish_count_%j.out
#SBATCH --error=logs/02_jellyfish_count_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=40G
#SBATCH --cpus-per-task=4
#SBATCH --partition=pshort_el8

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/jellyfish-2.2.6--0.sif"
INPUT_DIR="${PROJECT_DIR}/data/Qar-8a"
OUTPUT_DIR="${PROJECT_DIR}/results/02_count"

mkdir -p "${OUTPUT_DIR}"

# Execute counting and store count files
apptainer exec --bind /data "${CONTAINER}" jellyfish count \
    -C -m 21 -s 5G -t "${SLURM_CPUS_PER_TASK}" -o "${OUTPUT_DIR}/reads.jf" \
    <(zcat "${INPUT_DIR}"/*) \

if [ $? -ne 0 ]; then
    echo "Jellyfish count failed!" >&2
    exit 1
fi

echo "Task complete! Finished at $(date)"