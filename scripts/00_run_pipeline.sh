#!/bin/bash
PROJECT_DIR="$(pwd)"
mkdir -p "${PROJECT_DIR}"/{data,logs,results,scripts}
echo "Project structure created in ${PROJECT_DIR}"

# first job: quality control
JOB_QC=$(sbatch --parsable scripts/01_QC.sh)
echo "Submitted 01_qc.sh as job ${JOB_QC}"

# second job: kmer counts (after qc ran)
JOB_COUNTS=$(sbatch --parsable --dependency=afterok:${JOB_QC} scripts/02_count.sh)
echo "Submitted 02_counts.sh as job ${JOB_COUNTS}, waiting on ${JOB_QC}"

# third job: histograms (after counts ran)
JOB_HIST=$(sbatch --parsable --dependency=afterok:${JOB_COUNTS} scripts/03_hist.sh)
echo "Submitted 03_hist.sh as job ${JOB_HIST}, waiting on ${JOB_COUNTS}"

# fourth job: flye assembly (after QC ran)
JOB_FLYE=$(sbatch --parsable --dependency=afterok:${JOB_QC} scripts/04_flye_assembly.sh)
echo "Submitted 04_flye_assembly.sh as job ${JOB_FLYE}, waiting on ${JOB_QC}"

# fifth job: hifiasm assembly (after QC ran)
JOB_HIFI=$(sbatch --parsable --dependency=afterok:${JOB_QC} scripts/05_hifiasm_assembly.sh)
echo "Submitted 05_hifiasm_assembly.sh as job ${JOB_HIFI}, waiting on ${JOB_QC}"

# sixth job: lja assembly (after QC ran)
JOB_LJA=$(sbatch --parsable --dependency=afterok:${JOB_QC} scripts/06_lja_assembly.sh)
echo "Submitted 06_lja_assembly.sh as job ${JOB_LJA}, waiting on ${JOB_QC}"

# seventh job: trinity assembly (after QC ran)
JOB_TRIN=$(sbatch --parsable --dependency=afterok:${JOB_QC} scripts/07_trinity_assembly.sh)
echo "Submitted 07_trinity_assembly.sh as job ${JOB_TRIN}, waiting on ${JOB_QC}"

# eith job: busco (after all assemblies ran)
JOB_BUSCO=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA}:${JOB_TRIN} scripts/08_busco.sh)
echo "Submitted 08_busco.sh as job ${JOB_BUSCO}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}, ${JOB_TRIN}"

# ninth job: quast (after all assemblies ran)
JOB_QUAST=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA} scripts/09_quast.sh)
echo "Submitted 11_nucmer_mummer.sh as job ${JOB_QUAST}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}"

# tenth job: merqury (after all assemblies ran)
JOB_MERQURY=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA} scripts/10_merqury.sh)
echo "Submitted 11_nucmer_mummer.sh as job ${JOB_MERQURY}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}"

# eleventh job: nucmer (after all assemblies ran)
JOB_NUCMER=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA} scripts/11_nucmer_mummer.sh)
echo "Submitted 11_nucmer_mummer.sh as job ${JOB_NUCMER}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}"

