#!/usr/bin/env bash
#SBATCH --job-name=merqury_arabidopsis
#SBATCH --output=logs/10_merqury_%j.out
#SBATCH --error=logs/10_merqury_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

set -uo pipefail

PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

CONTAINER="/containers/apptainer/merqury_1.3.sif"
INPUT_DIR="${PROJECT_DIR}/data/results"
OUTPUT_DIR="${PROJECT_DIR}/results/10_merqury"
GENOME_SIZE=119667750   # same TAIR10 estimate used for QUAST --est-ref-size

# PacBioHiFi reads location
READS="${PROJECT_DIR}/data/Mh-0/ERR11437311.fastq.gz"

mkdir -p "${OUTPUT_DIR}" logs

# Assemblies to evaluate
FLYE="${INPUT_DIR}/04_flye_assembly/assembly.fasta"
HIFIASM="${INPUT_DIR}/05_hifiasm_assembly/Mh-0.p_ctg.fa"
LJA="${INPUT_DIR}/06_lja_assembly/XXXXXXX.fasta"           # check location
declare -A ASSEMBLIES=(
  [flye]="${FLYE}"
  [hifiasm]="${HIFIASM}"
  [lja]="${LJA}"
)

# Get best k for this genome size
K=$(apptainer exec --bind "${PROJECT_DIR}" "${CONTAINER}" \
      sh /usr/local/share/merqury/best_k.sh "${GENOME_SIZE}" | tail -n1 | awk '{print $NF}')
K=${K%.*}   # merqury.sh wants an integer k
echo "[INFO] using k=${K}"

# Build meryl db from reads
MERYL_DB="${OUTPUT_DIR}/reads.k${K}.meryl"
if [[ ! -d "${MERYL_DB}" ]]; then
  echo "[RUN] meryl count"
  apptainer exec --bind "${PROJECT_DIR}" "${CONTAINER}" \
    meryl count k="${K}" threads="${SLURM_CPUS_PER_TASK}" memory=55 \
      "${READS}" output "${MERYL_DB}"
fi

# Run merqury.sh per assembly
for name in "${!ASSEMBLIES[@]}"; do
  fasta="${ASSEMBLIES[$name]}"

  if [[ ! -f "${fasta}" ]]; then
    echo "[SKIP] ${name}: input not found at ${fasta}"
    continue
  fi

  outdir="${OUTPUT_DIR}/merqury_${name}"
  mkdir -p "${outdir}"

  echo "[RUN] merqury ${name}"
  apptainer exec --bind "${PROJECT_DIR}" --env MERQURY=/usr/local/share/merqury "${CONTAINER}" \
    bash -c "cd '${outdir}' && merqury.sh '${MERYL_DB}' '${fasta}' '${name}'"

  echo "[DONE] ${name}"
done