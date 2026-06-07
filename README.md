# catharanthus-rnaseq-pipeline
RNA-seq analysis pipeline for Catharanthus roseus across six tissues, highlighting terpenoid indole alkaloid (TIA) biosynthesis. Includes read alignment, quantification, and differential expression (DESeq2), demonstrating hairy roots as an optimal system.
# Catharanthus roseus RNA-seq Pipeline

This repository contains a reproducible RNA-seq analysis pipeline for *Catharanthus roseus*, including read alignment, quantification, and gene annotation.

## 📂 Project Structure
cr-genome-rnaseq-pipeline/
│
├── README.md
├── environment/
│   └── environment.yml
├── data/
│   ├── raw/              # (ignored)
│   ├── reference/
│   └── processed/
├── scripts/
│   ├── 01_download_reference.sh
│   ├── 02_index_genome.sh
│   ├── 03_align_reads.sh
│   ├── 04_postprocess_bam.sh
│   ├── 05_featurecounts.sh
│   └── 06_gene_annotation.py
├── config/
│   └── config.yaml
├── workflow/
│   └── pipeline_overview.md
├── results/
│
└── .gitignore
