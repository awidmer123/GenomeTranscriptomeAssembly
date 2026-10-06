#!/usr/bin/env bash
#SBATCH --job-name=merqury_arabidopsis
#SBATCH --output=logs/11_merqury_%j.out
#SBATCH --error=logs/11_merqury_%j.err
#SBATCH --time=05:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

set -uo pipefail

PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

CONTAINER="/containers/apptainer/merqury_1.3.sif"
INPUT_DIR="${PROJECT_DIR}/results"
OUTPUT_DIR="${PROJECT_DIR}/results/11_merqury"
GENOME_SIZE=119667750

# PacBio HiFi reads location
READS="${PROJECT_DIR}/data/Mh-0/ERR11437311.fastq.gz"

mkdir -p "${OUTPUT_DIR}"

# Assemblies to evaluate
FLYE="${INPUT_DIR}/05_flye_assembly/assembly.fasta"
HIFIASM="${INPUT_DIR}/06_hifiasm_assembly/Mh-0.p_ctg.fa"
LJA="${INPUT_DIR}/07_lja_assembly/assembly.fasta"
declare -A ASSEMBLIES=(
  [flye]="${FLYE}"
  [hifiasm]="${HIFIASM}"
  [lja]="${LJA}"
)

overall_status=0

# Get best k for this genome size
raw_k_output=$(apptainer exec --bind /data "${CONTAINER}" \
      sh /usr/local/share/merqury/best_k.sh "${GENOME_SIZE}")
echo "[DEBUG] best_k raw output: ${raw_k_output}"
K=$(echo "${raw_k_output}" | tail -n1 | awk '{print $NF}')
K=${K%.*}
echo "[INFO] using k=${K}"

# Build meryl db from reads
MERYL_DB="${OUTPUT_DIR}/reads.k${K}.meryl"
if [[ ! -d "${MERYL_DB}" ]]; then
  echo "[RUN] meryl count"
  apptainer exec --bind /data "${CONTAINER}" \
    meryl count k="${K}" threads="${SLURM_CPUS_PER_TASK}" memory=55 \
      "${READS}" output "${MERYL_DB}"
  status=$?
  if [[ $status -ne 0 ]]; then
    echo "[ERROR] meryl count failed (exit ${status}) - aborting, nothing downstream can work without the read db" >&2
    exit 1
  fi
fi

# Run merqury per assembly
for name in "${!ASSEMBLIES[@]}"; do
  fasta="${ASSEMBLIES[$name]}"

  if [[ ! -f "${fasta}" ]]; then
    echo "[SKIP] ${name}: input not found at ${fasta}"
    overall_status=1
    continue
  fi

  outdir="${OUTPUT_DIR}/merqury_${name}"
  rm -rf "${outdir}"
  mkdir -p "${outdir}"

  echo "[RUN] merqury ${name}"
  apptainer exec --bind /data --env MERQURY=/usr/local/share/merqury "${CONTAINER}" \
    bash -c "cd '${outdir}' && merqury.sh '${MERYL_DB}' '${fasta}' '${name}'"
  status=$?
  if [[ $status -ne 0 ]]; then
    echo "[ERROR] merqury ${name} failed (exit ${status})" >&2
    overall_status=1
  fi
  echo "[DONE] ${name}"
done

if [[ $overall_status -ne 0 ]]; then
  echo "One or more steps failed - check the .err log above" >&2
  exit 1
fi

echo "Task complete! Finished at $(date)"