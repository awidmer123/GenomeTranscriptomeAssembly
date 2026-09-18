#!/usr/bin/env bash
#SBATCH --job-name=hifiasm_arabidopsis
#SBATCH --output=logs/05_hifiasm_%j.out
#SBATCH --error=logs/05_hifiasm_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8


# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/hifiasm_0.25.0.sif" # set this path to your choice of container
INPUT_DIR="${PROJECT_DIR}/data/Qar-8a"
OUTPUT_DIR="${PROJECT_DIR}/results/05_hifiasm_assembly"

# Create directory in results
mkdir -p "${PROJECT_DIR}"/results/05_hifiasm_assembly

# Run hifiasm assembly (PacBio HiFi reads)
apptainer exec --bind /data "${CONTAINER}" hifiasm \
    -o "${OUTPUT_DIR}/Qar-8a" \
    -t "${SLURM_CPUS_PER_TASK}" \
    "${INPUT_DIR}"/*.fastq.gz

if [ $? -ne 0 ]; then
    echo "hifiasm failed!" >&2
    exit 1
fi

# Convert primary contig .gfa to .fasta
awk '/^S/{print ">"$2;print $3}' "${OUTPUT_DIR}/Qar-8a.bp.p_ctg.gfa" > "${OUTPUT_DIR}/Qar-8a.p_ctg.fa"

if [ $? -ne 0 ]; then
    echo "GFA to FASTA conversion failed!" >&2
    exit 1
fi

echo "Task complete! Finished at $(date)""
