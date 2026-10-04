#!/bin/bash
# Submits ONLY the assembly jobs and their evaluation (busco, quast, merqury,
# nucmer). Steps 00_setup.sh, 01_QC.sh, 02_fastp.sh, 03_count.sh and 04_hist.sh are run
# manually beforehand

PROJECT_DIR="$(pwd)"
mkdir -p "${PROJECT_DIR}"/{data,logs,results,scripts}
echo "Project structure created in ${PROJECT_DIR}"

# first job: flye assembly
JOB_FLYE=$(sbatch --parsable scripts/05_flye.sh)
echo "Submitted 05_flye.sh as job ${JOB_FLYE}"

# second job: hifiasm assembly
JOB_HIFI=$(sbatch --parsable scripts/06_hifiasm.sh)
echo "Submitted 06_hifiasm.sh as job ${JOB_HIFI}"

# third job: lja assembly
JOB_LJA=$(sbatch --parsable scripts/07_lja.sh)
echo "Submitted 07_lja.sh as job ${JOB_LJA}"

# fourth job: trinity assembly
JOB_TRIN=$(sbatch --parsable scripts/08_trinity.sh)
echo "Submitted 08_trinity.sh as job ${JOB_TRIN}"

# fifth job: busco (after all four assemblies ran)
JOB_BUSCO=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA}:${JOB_TRIN} scripts/09_busco.sh)
echo "Submitted 09_busco.sh as job ${JOB_BUSCO}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}, ${JOB_TRIN}"

# sixth job: quast (after the genome assemblies ran)
JOB_QUAST=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA} scripts/10_quast.sh)
echo "Submitted 10_quast.sh as job ${JOB_QUAST}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}"

# seventh job: merqury (after the genome assemblies ran)
JOB_MERQURY=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA} scripts/11_merqury.sh)
echo "Submitted 11_merqury.sh as job ${JOB_MERQURY}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}"

# eighth job: nucmer (after the genome assemblies ran)
JOB_NUCMER=$(sbatch --parsable --dependency=afterok:${JOB_FLYE}:${JOB_HIFI}:${JOB_LJA} scripts/12_nucmer.sh)
echo "Submitted 12_nucmer.sh as job ${JOB_NUCMER}, waiting on ${JOB_FLYE}, ${JOB_HIFI}, ${JOB_LJA}"