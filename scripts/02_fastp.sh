#!/usr/bin/env bash
#SBATCH --job-name=fastp_rnaseq_trim_and_hifi_stats
#SBATCH --output=logs/02_fastp_%j.out
#SBATCH --error=logs/02_fastp_%j.err
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=4
#SBATCH --partition=pshort_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

set -uo pipefail
shopt -s nullglob

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Container
CONTAINER="/containers/apptainer/fastp_0.24.1.sif"

INPUT_DIR_RNA="${PROJECT_DIR}/data/RNAseq_Sha"
INPUT_DIR_HIFI="${PROJECT_DIR}/data/Mh-0"
OUTPUT_DIR_RNA="${PROJECT_DIR}/results/02_fastp/RNA_trimmed"
OUTPUT_DIR_HIFI="${PROJECT_DIR}/results/02_fastp/HiFi_stats"

mkdir -p "${OUTPUT_DIR_RNA}" "${OUTPUT_DIR_HIFI}"

overall_status=0

# For Illumina RNAseq, paired-end: filter + trim with normal defaults
r1_files=("${INPUT_DIR_RNA}"/*_1.fastq.gz)
echo "Found ${#r1_files[@]} RNA R1 files in ${INPUT_DIR_RNA}"

for r1 in "${r1_files[@]}"; do
    r2="${r1/_1.fastq.gz/_2.fastq.gz}"
    sample=$(basename "${r1}" _1.fastq.gz)

    if [ ! -f "${r2}" ]; then
        echo "No matching R2 for ${r1} (expected ${r2}) - skipping" >&2
        overall_status=1
        continue
    fi

    apptainer exec --bind /data "${CONTAINER}" fastp \
        -i "${r1}" -I "${r2}" \
        -o "${OUTPUT_DIR_RNA}/${sample}_1.trimmed.fastq.gz" \
        -O "${OUTPUT_DIR_RNA}/${sample}_2.trimmed.fastq.gz" \
        -j "${OUTPUT_DIR_RNA}/${sample}.fastp.json" \
        -h "${OUTPUT_DIR_RNA}/${sample}.fastp.html" \
        -w "${SLURM_CPUS_PER_TASK}"
    status=$?
    if [ $status -ne 0 ]; then
        echo "fastp failed for RNA sample ${sample}" >&2
        overall_status=1
    fi
done

# For PacBio HiFi
hifi_files=("${INPUT_DIR_HIFI}"/*.fastq.gz)
echo "Found ${#hifi_files[@]} HiFi fastq.gz files in ${INPUT_DIR_HIFI}"

for f in "${hifi_files[@]}"; do
    base=$(basename "${f}" .fastq.gz)

    apptainer exec --bind /data "${CONTAINER}" fastp \
        -i "${f}" \
        -o /dev/null \
        --disable_adapter_trimming \
        --disable_quality_filtering \
        --disable_length_filtering \
        -j "${OUTPUT_DIR_HIFI}/${base}.fastp.json" \
        -h "${OUTPUT_DIR_HIFI}/${base}.fastp.html" \
        -w "${SLURM_CPUS_PER_TASK}"
    status=$?
    if [ $status -ne 0 ]; then
        echo "fastp failed for HiFi file ${f}" >&2
        overall_status=1
    fi
done

if [ $overall_status -ne 0 ]; then
    echo "One or more fastp runs failed - check the .err log above" >&2
    exit 1
fi

echo "Task complete! Finished at $(date)"