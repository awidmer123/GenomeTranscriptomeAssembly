#!/usr/bin/env bash
#SBATCH --job-name=quast_arabidopsis
#SBATCH --output=logs/09_quast_%j.out
#SBATCH --error=logs/09_quast_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

set -uo pipefail

PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

CONTAINER="/containers/apptainer/quast_5.2.0.sif"
INPUT_DIR="${PROJECT_DIR}/data/results"
OUTPUT_DIR="${PROJECT_DIR}/results/09_quast"
REF_DIR="/data/courses/assembly-annotation-course/references"

mkdir -p "${OUTPUT_DIR}/with_ref" "${OUTPUT_DIR}/no_ref" logs

# reference files
REFERENCE="${REF_DIR}/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"
ANNOTATION="${REF_DIR}/TAIR10_GFF3_genes.gff"
EST_REF_SIZE=119667750 # extrected with: grep -v '^>' /data/courses/assembly-annotation-course/references/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa | tr -d '\n' | wc -c

# output paths
FLYE="${INPUT_DIR}/04_flye_assembly/assembly.fasta"
HIFIASM="${INPUT_DIR}/05_hifiasm_assembly/Mh-0.p_ctg.fa"
LJA="${INPUT_DIR}/06_lja_assembly/XXXXXXX.fasta"           # check location

ASSEMBLIES=("${FLYE}" "${HIFIASM}" "${LJA}")
LABELS="flye,hifiasm,lja"

echo "[RUN] QUAST with reference"
apptainer exec --bind "${PROJECT_DIR}" --bind "${REF_DIR}" "${CONTAINER}" quast.py \
  "${ASSEMBLIES[@]}" \
  -r "${REFERENCE}" \
  --features "${ANNOTATION}" \
  --labels "${LABELS}" \
  --eukaryote \
  --threads "${SLURM_CPUS_PER_TASK}" \
  -o "${OUTPUT_DIR}/with_ref"
  # --pacbio /path/to/hifi_reads.fastq.gz   # add if you want read-based SV/misassembly calls

echo "[RUN] QUAST without reference"
apptainer exec --bind "${PROJECT_DIR}" "${CONTAINER}" quast.py \
  "${ASSEMBLIES[@]}" \
  --est-ref-size "${EST_REF_SIZE}" \
  --labels "${LABELS}" \
  --eukaryote \
  --no-sv \
  --threads "${SLURM_CPUS_PER_TASK}" \
  -o "${OUTPUT_DIR}/no_ref"

echo "[DONE]"