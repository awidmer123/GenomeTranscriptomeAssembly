#!/bin/bash
PROJECT_DIR="$(pwd)"
mkdir -p "${PROJECT_DIR}"/{data,logs,results,scripts}
echo "Project structure created in ${PROJECT_DIR}"

# first job: quality control
JOB_QC=$(sbatch --parsable 01_QC.sh)
echo "Submitted 01_qc.sh as job ${JOB_QC}"

# second job: kmer counts
JOB_COUNTS=$(sbatch --parsable --dependency=afterok:${JOB_QC} 02_counts.sh)
echo "Submitted 02_counts.sh as job ${JOB_COUNTS}, waiting on ${JOB_QC}"

# third job: histograms
JOB_HIST=$(sbatch --parsable --dependency=afterok:${JOB_COUNTS} 03_hist.sh)
echo "Submitted 03_ist.sh as job ${JOB_HIST}, waiting on ${JOB_COUNTS}"

# fourth job: flye assembly
JOB_FLYE=$(sbatch --parsable --dependency=afterok:${JOB_HIST} 04_flye_assembly.sh)
echo "Submitted 04_flye_assembly.sh as job ${JOB_FLYE}, waiting on ${JOB_HIST}"

# fifth job: hifiasm assembly
JOB_HIFI=$(sbatch --parsable --dependency=afterok:${JOB_HIST} 05_hifiasm_assembly.sh)
echo "Submitted 05_hifiasm_assembly.sh as job ${JOB_HIFI}, waiting on ${JOB_HIST}"

# sixth job: lja assembly
JOB_LJA=$(sbatch --parsable --dependency=afterok:${JOB_HIST} 06_lja_assembly.sh)
echo "Submitted 06_lja_assembly.sh as job ${JOB_LJA}, waiting on ${JOB_HIST}"

# seventh job: trinity assembly
JOB_TRIN=$(sbatch --parsable --dependency=afterok:${JOB_HIST} 07_trinity_assembly.sh)
echo "Submitted 07_trinity_assembly.sh as job ${JOB_TRIN}, waiting on ${JOB_HIST}"