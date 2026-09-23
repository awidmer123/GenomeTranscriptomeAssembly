# GenomeTranscriptomeAssembly

Genome and transcriptome assembly pipeline for *Arabidopsis thaliana* accession Mh-0.

## Overview

SLURM-based pipeline for genome assembly from PacBio HiFi reads (multiple assemblers compared) and transcriptome assembly from RNA-seq data (accession Sha), for downstream comparison/annotation.

## Structure
```
├── data/
│ ├── Qar-8a/ # PacBio HiFi reads
│ └── RNAseq_Sha/ # paired-end RNA-seqreads (_1/_2)
├── logs/ # SLURM job logs
├── results/ # pipeline outputs per step
└── scripts/ # pipeline scripts 
```

## Pipeline steps

| Script | Description | Tool / Version |
|---|---|---|
| `00_run_pipeline.sh` | Sets up directories, submits all jobs with dependencies | — |
| `01_qc.sh` | FastQC on Qar-8a (HiFi) and RNAseq_Sha reads | fastqc-0.12.1 (Apptainer) |
| `02_jellyfish_count.sh` | k-mer counting on Qar-8a (HiFi only), for genome size estimation | jellyfish-2.2.6 (Apptainer) |
| `03_jellyfish_histo.sh` | k-mer histogram from count output | jellyfish-2.2.6 (Apptainer) |
| `04_flye.sh` | Genome assembly (PacBio HiFi) | flye 2.9.5 (Apptainer) |
| `05_hifiasm.sh` | Genome assembly (PacBio HiFi) | hifiasm 0.25.0 (Apptainer) |
| `06_lja.sh` | Genome assembly (PacBio HiFi) | LJA 0.2 (Apptainer) |
| `07_trinity.sh` | Transcriptome assembly (RNAseq_Sha, paired-end) | Trinity 2.15.1-foss-2021a (module) |

Steps 04–06 run in parallel after QC/preprocessing; results are intended for downstream comparison (e.g. QUAST, BUSCO).

## Setup (first time)

```bash
git clone https://github.com/awidmer123/GenomeTranscriptomeAssembly.git
cd GenomeTranscriptomeAssembly
chmod +x scripts/*.sh
bash scripts/00_run_pipeline.sh
```

`data/`, `logs/`, and `results/` are gitignored and get created by `00_run_pipeline.sh`, so make sure `data/Qar-8a/` (HiFi reads) and `data/RNAseq_Sha/` (RNA-seq, `_1`/`_2`) are populated before running.

## Usage as soon as setup is done

```bash
cd ~/GenomeTranscriptomeAssembly
bash 00_run_pipeline.sh
```

Each script is submitted via `sbatch` with `--dependency=afterok:<jobid>` to chain the pipeline. Job scripts are not meant to be run manually with `sbatch` unless testing a single step.

## Requirements

- SLURM cluster (partitions used: `pshort_el8`, `pibu_el8`)
- Apptainer containers:
  - `/containers/apptainer/fastqc-0.12.1.sif`
  - `/container/apptainer/jellyfish-2.2.6--0.sif`
  - `/containers/apptainer/flye_2.9.5.sif`
  - `/containers/apptainer/hifiasm_0.25.0.sif`
  - `/containers/apptainer/lja-0.2.sif`
- Module: `Trinity/2.15.1-foss-2021a`

## Notes

- Genome size estimate used for Flye: ~130 Mb 
- Qar-8a assumed homozygous
