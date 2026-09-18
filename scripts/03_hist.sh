#!/usr/bin/env bash
#SBATCH --job-name=jellyfish_histo_arabidopsis
#SBATCH --output=logs/03_hist_%j.out
#SBATCH --error=logs/03_hist_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=50G
#SBATCH --cpus-per-task=1
#SBATCH --partition=pibu_el8


# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR: -$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/jellyfish-2.2.6--0.sif" # set this path to your choice of container
INPUT_DIR="${PROJECT_DIR}/data/02_counts"
OUTPUT_DIR="${PROJECT_DIR}/results/03_hist"

# Create directory in results
mkdir -p "${PROJECT_DIR}"/results/03_hist

# Execute historgram 
apptainer exec --bind /data ${CONTAINER} histo \
-t 4 ${INPUT_DIR}/reads.jf > ${OUTPUT_DIR}/reads.histo \

echo "Task complete! Finished at $(date)""
