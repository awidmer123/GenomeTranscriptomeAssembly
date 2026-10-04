# GenomeTranscriptomeAssembly

This is the repository used for the semester project of the Uni Bern Course "Genome and Transcriptome Assembly". A genome and transcriptome assembly pipeline for *Arabidopsis thaliana* with accession Mh-0 was built. 

## Overview

SLURM-based pipeline for genome assembly from PacBio HiFi reads (accession Mh-0; multiple assemblers compared) and transcriptome assembly from RNA-seq data (accession Sha), for downstream comparison.

## Structure
```
├── data/
│ ├── Mh-0/           # PacBio HiFi reads
│ └── RNAseq_Sha/     # paired-end RNA-seq reads (_1/_2)
├── logs/              # SLURM job logs
├── results/           # pipeline outputs per step
└── scripts/           # pipeline scripts
```

## Pipeline steps

| Script | Description | Tool / Version | Run |
|---|---|---|---|
| `01_QC.sh` | FastQC on Mh-0 (HiFi) and RNAseq_Sha reads | fastqc-0.12.1 (Apptainer) | manual |
| `02_fastp.sh` | Quality trimming / adapter removal | fastp (Apptainer) | manual |
| `03_count.sh` | k-mer counting on Mh-0 (HiFi only), for genome size estimation | jellyfish-2.2.6 (Apptainer) | manual |
| `04_hist.sh` | k-mer histogram from count output | jellyfish-2.2.6 (Apptainer) | manual |
| `05_flye.sh` | Genome assembly (PacBio HiFi) | flye 2.9.5 (Apptainer) | automatic |
| `06_hifiasm.sh` | Genome assembly (PacBio HiFi) | hifiasm 0.25.0 (Apptainer) | automatic |
| `07_lja.sh` | Genome assembly (PacBio HiFi) | LJA 0.2 (Apptainer) | automatic |
| `08_trinity.sh` | Transcriptome assembly (RNAseq_Sha, paired-end) | Trinity 2.15.1-foss-2021a (module) | automatic |
| `09_busco.sh` | Completeness evaluation of all four assemblies | busco (Apptainer) | automatic |
| `10_quast.sh` | Genome assembly QC/comparison (flye, hifiasm, lja) | quast (Apptainer) | automatic |
| `11_merqury.sh` | k-mer-based assembly QC (flye, hifiasm, lja) | merqury (Apptainer) | automatic |
| `12_nucmer.sh` | Pairwise assembly comparison (flye, hifiasm, lja) | MUMmer/nucmer (Apptainer) | automatic |

`00_run_pipeline.sh` only submits steps **05–12**. Steps **01–04** are run by hand first: QC, trimming and k-mer counting serve a different purpose than assembling (checking the data, extracting/adjusting parameters such as the genome size estimate or trimming settings), so they're not triggered by the same script as the assemblies.

Steps 05–08 run in parallel; 09–12 wait on the relevant assemblies via `--dependency=afterok`.

## Setup (first time)

```bash
git clone https://github.com/awidmer123/GenomeTranscriptomeAssembly.git
cd GenomeTranscriptomeAssembly
chmod +x scripts/*.sh
```

`data/`, `logs/`, and `results/` are gitignored and get created by `00_run_pipeline.sh`, so make sure `data/Mh-0/` (HiFi reads) and `data/RNAseq_Sha/` (RNA-seq, `_1`/`_2`) are populated before running.

## Usage

**1. Manual pre-processing**: run these by hand, in order, and check the output of each before moving on:

```bash
cd ~/GenomeTranscriptomeAssembly
bash scripts/00_setup.sh
bash scripts/01_QC.sh
bash scripts/02_fastp.sh
bash scripts/03_count.sh
bash scripts/04_hist.sh
```

Use this step to setup the directory and to extract whatever the remaining steps need (genome size estimate from the k-mer histogram, trimming settings and read quality from FastQC/fastp).

**2. Automated assembly and evaluation**

```bash
bash scripts/run_pipeline.sh
```

This submits `scripts/05_flye.sh` through `scripts/12_nucmer.sh` via `sbatch`, chained with `--dependency=afterok:<jobid>` where needed. Job scripts are not meant to be run manually with `sbatch` unless testing a single step.

## Requirements

- SLURM cluster (partitions used: `pshort_el8`, `pibu_el8`)
- Apptainer containers:
  - `/containers/apptainer/fastqc-0.12.1.sif`
  - `/containers/apptainer/fastp_0.24.1.sif`
  - `/containers/apptainer/jellyfish-2.2.6--0.sif`
  - `/containers/apptainer/flye_2.9.5.sif`
  - `/containers/apptainer/hifiasm_0.25.0.sif`
  - `/containers/apptainer/lja-0.2.sif`
  - `/containers/apptainer/busco_5.7.1.sif`
  - `/containers/apptainer/quast_5.2.0.sif`
  - `/containers/apptainer/merqury_1.3.sif`
  - `/containers/apptainer/mummer4_gnuplot.sif`
- Module: `Trinity/2.15.1-foss-2021a`

## Notes

The HiFi reads are of good quality. With the default parameters of fastp nothing was trimmed. For the HiFi assemblies it is suggested to use only the raw reads. Yet for the RNA reads, certain trimming was done by fastp. Therefore, the the trinity assembly can be run on both reads (Don't forget to adjust the path!).

