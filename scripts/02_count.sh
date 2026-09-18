#!/usr/bin/env bash
#SBATCH --job-name=jellyfish_count_arabidopsis
#SBATCH --output=logs/02_jellyfish_count_%j.out
#SBATCH --error=logs/02_jellyfish_count_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=40G
#SBATCH --cpus-per-task=4
#SBATCH --partition=pshort_el8



# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR: -$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/jellyfish-2.2.6--0.sif" # set this path to your choice of container
INPUT_DIR="${PROJECT_DIR}/data/"
OUTPUT_DIR="${PROJECT_DIR}/results/02_count"

# Create directory in results
mkdir -p "${PROJECT_DIR}"/results/02_count


# Execute counting and store count files
apptainer exec --bind /data ${CONTAINER} count \
-C -m 21 -s 5G -t 4 -o ${OUTPUT_DIR}/reads.jf \
<(zcat ${INPUT_DIR}/Qar-8a/*) \
<(zcat ${INPUT_DIR}/RNAseq_Sha/*)

echo "Task complete! Finished at $(date)""
