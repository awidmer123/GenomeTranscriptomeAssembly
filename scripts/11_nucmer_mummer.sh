#!/usr/bin/env bash
#SBATCH --job-name=mummer_arabidopsis
#SBATCH --output=logs/11_mummer_%j.out
#SBATCH --error=logs/11_mummer_%j.err
#SBATCH --time=1-00:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --partition=pibu_el8
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=andri.widmer@unifr.ch

set -uo pipefail

PROJECT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"

CONTAINER="/containers/apptainer/mummer4_gnuplot.sif"
INPUT_DIR="${PROJECT_DIR}/data/results"
OUTPUT_DIR="${PROJECT_DIR}/results/11_mummer"
REF_DIR="/data/courses/assembly-annotation-course/references"

REFERENCE="${REF_DIR}/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"

mkdir -p "${OUTPUT_DIR}/vs_ref" "${OUTPUT_DIR}/pairwise" logs

# Path to assemblies
FLYE="${INPUT_DIR}/04_flye/assembly/XXXXXXX.fasta"        # check location
HIFIASM="${INPUT_DIR}/05_hifiasm_assembly/Mh-0.p_ctg.fa"
LJA="${INPUT_DIR}/06_lja_assembly/XXXXXXX.fasta"           # check location

declare -A ASSEMBLIES=(
  [flye]="${FLYE}"
  [hifiasm]="${HIFIASM}"
  [lja]="${LJA}"
)

run_nucmer_and_plot () {
  local prefix="$1" ref="$2" query="$3" outdir="$4"

  echo "[RUN] nucmer ${prefix}"
  apptainer exec --bind "${PROJECT_DIR}" --bind "${REF_DIR}" "${CONTAINER}" \
    nucmer --prefix="${outdir}/${prefix}" \
           --breaklen 1000 \
           --mincluster 1000 \
           --threads "${SLURM_CPUS_PER_TASK}" \
           "${ref}" "${query}"

  echo "[RUN] mummerplot ${prefix}"
  apptainer exec --bind "${PROJECT_DIR}" --bind "${REF_DIR}" "${CONTAINER}" \
    mummerplot --prefix="${outdir}/${prefix}" \
               -R "${ref}" -Q "${query}" \
               --filter -t png --large --layout --fat \
               "${outdir}/${prefix}.delta"

  echo "[DONE] ${prefix}"
}

# Each assebly vs reference genome
for name in "${!ASSEMBLIES[@]}"; do
  fasta="${ASSEMBLIES[$name]}"
  if [[ ! -f "${fasta}" ]]; then
    echo "[SKIP] ${name}: input not found at ${fasta}"
    continue
  fi
  run_nucmer_and_plot "${name}_vs_ref" "${REFERENCE}" "${fasta}" "${OUTPUT_DIR}/vs_ref"
done

# Assebly vs assembly
PAIRS=("flye hifiasm" "flye lja" "hifiasm lja")
for pair in "${PAIRS[@]}"; do
  read -r a b <<< "${pair}"
  fasta_a="${ASSEMBLIES[$a]}"
  fasta_b="${ASSEMBLIES[$b]}"
  if [[ ! -f "${fasta_a}" || ! -f "${fasta_b}" ]]; then
    echo "[SKIP] ${a}_vs_${b}: missing input"
    continue
  fi
  run_nucmer_and_plot "${a}_vs_${b}" "${fasta_a}" "${fasta_b}" "${OUTPUT_DIR}/pairwise"
done

echo "[ALL DONE]"