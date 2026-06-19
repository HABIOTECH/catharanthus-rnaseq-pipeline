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
│   ├── Cr_RNAseq_pipeline.sh   # Full RNA-seq workflow (bash)
│   └── python_code.py          # DEG extraction and annotation
├── workflow/
│   └── pipeline_overview.md
├── figures/
│   ├── catharanthus_abstract_v5_clean.svg
│   └── Catharansus_RNA-Seq_pipeline.png
├── results/            # (ignored)
│
└── .gitignore

## 📌 Project Summary
Catharanthus roseus (Madagascar periwinkle) is the sole natural source of vincristine and vinblastine—clinically essential terpenoid indole alkaloid (TIA) anticancer drugs listed as WHO essential medicines. Hairy roots (HR) were induced from leaf explants using Agrobacterium rhizogenes, and bulk RNA-seq was performed across six tissues (HR, IL, ML, St, Rt, and SC). Principal component analysis (PCA) explained 90% of the variance, clearly separating HR and IL (biosynthetically active states) from St and Rt (vascular-associated programs). Differential expression analysis using DESeq2, together with GO and pathway enrichment analyses, revealed significant upregulation of secologanin and strictosidine biosynthetic pathways in HR relative to all other tissues, establishing hairy roots as an optimal system for TIA biosynthesis research.

## 👥 Research Team
Bioinformatics team - Horizon Science Communication LLC
https://www.horizon-sci-comm.us/bioinformatics-services

- Abeer Farag, PhD  
- Hesham Abdullah, PhD  

## 📊 Data Sources

### RNA-seq Data

- **Study:** Catharanthus roseus RNA-Seq (Medicinal Plants Consortium)  
- **Accession:** SRP005953  
- **Platform:** Illumina RNA Sequencing  
- **Description:** Transcriptome analysis of *Catharanthus roseus* across multiple tissues.

🔗 [NCBI SRA Study (SRP005953)](https://www.ncbi.nlm.nih.gov/sra?term=SRP005953)

---

### Reference Genomes

- **NCBI Reference Genome:**
  GCA_024505715.1 (*Catharanthus roseus*)  
  🔗 [Download from NCBI](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/024/505/715/GCA_024505715.1_ASM2450571v1/)

- **Alternative Genome Resource:**
  CroFGD database  
  🔗 [Download from CAU Bioinformatics](https://bioinformatics.cau.edu.cn/croFGD/download.php)

  ### Related Publication

- Gongora et al. (Medicinal Plants Consortium study)  
- 🔗 [PubMed: Iridoid biosynthesis study](https://pubmed.ncbi.nlm.nih.gov/23172143/)
``

## 🧬 Research Overview

![Overview](catharanthus_abstract_v5_clean.svg)


## ⚙️ RNA-seq Analysis Workflow

### Phase 1: Setup
- HPC job submission (SGE / Slurm)

### Phase 2: Core Pipeline
1. Download reference genome (NCBI)
2. Build HISAT2 index
3. Align RNA-seq reads
4. Convert SAM → sorted BAM (SAMtools)
5. Generate gene counts (featureCounts)
6. Extract gene lengths (gtftools)
7. Extract DEG sequences (Python)

### Phase 3: Extended Analysis
- Re-mapping to alternative genome
- Alignment QC (flagstat)


## ⚙️ RNA-seq Analysis Workflow

<p align="center">
  <img src="Catharansus_RNA-Seq_pipeline.png" alt="RNA-seq pipeline" width="900">
</p>





