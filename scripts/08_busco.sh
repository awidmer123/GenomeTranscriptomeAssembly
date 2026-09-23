#!/usr/bin/env bash
#SBATCH --job-name=busco_arabidopsis
#SBATCH --output=logs/08_busco_%j.out
#SBATCH --error=logs/08_busco_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

set -uo pipefail   # no -e: one failed assembly shouldn't kill the whole loop

# Project-Root
PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

# Set paths
CONTAINER="/containers/apptainer/busco_5.7.1.sif"
INPUT_DIR="${PROJECT_DIR}/data/results"
OUTPUT_DIR="${PROJECT_DIR}/results/08_busco"

mkdir -p "${OUTPUT_DIR}"

# Use fixed lineage or let BUSCO auto-select (fixed lineage was used)
USE_AUTO_LINEAGE=false
LINEAGE="brassicales_odb10"

# name -> "path/to/assembly.fasta|mode"
declare -A ASSEMBLIES=(
  [flye]="${INPUT_DIR}/04_flye_assembly/assembly.fasta|genome"
  [hifiasm]="${INPUT_DIR}/05_hifiasm_assembly/Mh-0.p_ctg.fa|genome"
  [lja]="${INPUT_DIR}/06_lja_assembly/XXXXXXX.fasta|genome"                 #check location
  [trinity]="${INPUT_DIR}/07_trinity_assembly/XXXXX.fasta|transcriptome"   #check location
)

for name in "${!ASSEMBLIES[@]}"; do
  IFS='|' read -r fasta mode <<< "${ASSEMBLIES[$name]}"

  if [[ ! -f "${fasta}" ]]; then
    echo "[SKIP] ${name}: input not found at ${fasta}"
    continue
  fi

  echo "[RUN] ${name} (mode=${mode})"

  if [[ "${USE_AUTO_LINEAGE}" == true ]]; then
    LINEAGE_ARGS="--auto-lineage"
  else
    LINEAGE_ARGS="-l ${LINEAGE}"
  fi

  apptainer exec --bind "${PROJECT_DIR}" "${CONTAINER}" busco \
    -i "${fasta}" \
    -o "busco_${name}" \
    -m "${mode}" \
    ${LINEAGE_ARGS} \
    -c "${SLURM_CPUS_PER_TASK}" \
    --out_path "${OUTPUT_DIR}" \
    -f

  echo "[DONE] ${name}"
done